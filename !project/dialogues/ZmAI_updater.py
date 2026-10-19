#!/usr/bin/env python3
import argparse
import difflib
import json
import os
import random
import re
import string
import sys
import time
import unicodedata
import urllib.error
import urllib.request
import urllib.robotparser
from html.parser import HTMLParser
from pathlib import Path

#adds new dialogues to content/, one voting stop and personality at a time, never touching existing files
#stage 1: ZmAI writes a dialogue without points from the ZmAI_dialogues.md rules, the existing dialogues and Crta Q&A
#everything sent to ZmAI is worded in ZmAI_dialogues.md and ZmAI_prompts.md, this script only fills it in
#stage 2: the dialogue goes back to ZmAI, which rates each answer by the severity of the violation
#the levels turn into points balanced to the average and maximum run targets
#prompts longer than one ZmAI message go out as numbered parts in one thread
#ZmAI threads are kept short: one compact sample, no rules samples, the rating in its own thread
#--fast spaces ZmAI requests closer; its first ZmAI failure stops the run and restarts it at the normal pace
#an incomplete or unusable ZmAI answer, or a message ZmAI refuses, is flagged in red and its pair retried in a new thread
DIALOGUES_DIR = Path(__file__).resolve().parent
CONTENT_DIR = DIALOGUES_DIR / "content"
PROMPT_RULES_PATH = DIALOGUES_DIR / "ZmAI_dialogues.md"
ZMAI_PROMPTS_PATH = DIALOGUES_DIR / "ZmAI_prompts.md"
INFO_TEXTS_PATH = DIALOGUES_DIR / "info_texts.json"
# hidden, so Godot never imports it
CACHE_DIR = DIALOGUES_DIR / ".updater_cache"
CRTA_CACHE_DIR = CACHE_DIR / "crta"
DRAFTS_DIR = CACHE_DIR / "drafts"
CALIBRATION_PATH = CACHE_DIR / "calibration.json"

DIALOGUE_FILENAME = "voter_{topic}_dialog_{personality}_{index:02d}.json"
DIALOGUE_FILENAME_PATTERN = re.compile(r"voter_(\w+?)_dialog_(angry|polite)_(\d+)\.json")
# info_texts.json keys of the stops holding dialogues; Box has none
DIALOGUE_STOPS = ["Lamp", "ID", "List", "Spray", "Ballot", "Booth"]

# points goal of the whole dialogue pool
TARGET_MAX_RUN_POINTS = 6_500_000
TARGET_AVERAGE_RUN_POINTS = 2_000_000
AVERAGE_PLAYER_ACCURACY = 0.75
# keeps a negative-points scale off the extremes so penalties stay ordered and meaningful
NEGATIVE_SCALE_LIMITS = (0.5, 2.0)

ZMAI_MIN_DELAY = 40.0
ZMAI_DELAY_JITTER = 20.0
ZMAI_MAX_REQUESTS_PER_RUN = 85
# --fast pacing, more likely to be throttled or blocked
ZMAI_FAST_MIN_DELAY = 10.0
ZMAI_FAST_DELAY_JITTER = 5.0
# assumed input limit of one ZmAI message; longer prompts are split into parts
ZMAI_MAX_MESSAGE_CHARS = 4000
CRTA_MIN_DELAY = 12.0
CRTA_DELAY_JITTER = 8.0
CRTA_MAX_REQUESTS_PER_RUN = 40
# retry waits double from this, unless the server sends Retry-After
BACKOFF_BASE_DELAY = 120.0
MAX_ATTEMPTS = 3
RETRYABLE_HTTP_CODES = {429, 500, 502, 503, 504}
# ZmAI's answer to a message its filter rejects; fails the pair, not the run
REFUSED_MESSAGE_HTTP_CODE = 422

ZMAI_API_URL = "https://vernestra.app/api/assistant-chat/chat/stream"
ZMAI_ASSISTANT_ID = "c764b9e5-3ab9-40a6-a36f-ba2ab36bfcb8"
# same headers the zmai.crta.rs page sends from a browser
ZMAI_REQUEST_HEADERS = {
    "Content-Type": "application/json",
    "Origin": "https://zmai.crta.rs",
    "Referer": "https://zmai.crta.rs/",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0 Safari/537.36",
}
# names this script openly, so crta.rs can tell it apart from browsers and block it if it wants
CRTA_USER_AGENT = "glasalica-dialogue-updater/1.0 (+https://github.com/kreativna-blokada/blokadna-glasalica)"

CRTA_HOME_URL = "https://crta.rs/"
CRTA_QA_LISTING_URL = "https://crta.rs/kategorija/q_a/"
CRTA_QA_MAX_LISTING_PAGES = 15
CRTA_LISTING_MAX_AGE = 7 * 24 * 3600
CRTA_EXCERPT_LIMIT = 3500
CRTA_ARTICLE_LINK_PATTERN = re.compile(r'href="https://crta\.rs/([a-z0-9\-]+)/"')
CRTA_NON_ARTICLE_SLUGS = {"kategorija", "tag", "page", "wp-content", "wp-json", "feed", "author"}
CLOUDFLARE_BLOCK_MARKERS = ("Attention Required! | Cloudflare", "cf-challenge", "challenge-platform")
# matched against lowercase text with diacritics stripped, so slugs match too
TOPIC_PATTERNS = {
    "lamp": re.compile(r"\buv\b|lamp|skenir"),
    "id": re.compile(r"licn\w* kart|pasos|identitet|jmbg|potvrd\w* mup"),
    "list": re.compile(r"biracki\w* spis|izvod\w* iz|potpis"),
    "spray": re.compile(r"sprej|prsk|nevidljiv"),
    "ballot": re.compile(r"glasack\w* listi|listic"),
    "booth": re.compile(r"paravan|tajnost|fotografis|zaokruz|presavi"),
}

# root texts this close to an existing one count as a repeated scenario
DUPLICATE_ROOT_RATIO = 0.75
# every text of the existing dialogues ends with one of these, a cut-off ZmAI answer does not
SENTENCE_ENDINGS = (".", "!", "?", "…", '"', "”", "»", ")")
# tries per pair before an unusable ZmAI answer skips it
DRAFT_ATTEMPTS = 3
# end of the raw ZmAI answer shown with a failure
FAILURE_ANSWER_TAIL_CHARS = 300
# start of a ZmAI error response shown with a failure
ERROR_BODY_CHARS = 500
# start of a refused ZmAI message shown with a failure
REFUSED_MESSAGE_HEAD_CHARS = 200
# existing dialogues of the stop and personality sent as samples, newest first
SAMPLE_DIALOGUES_PER_PROMPT = 1


class ServiceBlocked(Exception):
    pass


class RequestBudgetExhausted(Exception):
    pass


class FastPaceBroken(Exception):
    pass


# a ZmAI answer that stays invalid after its correction, keeping the raw answer for the failure banner
class UnusableAnswer(ValueError):
    def __init__(self, answer_error, answer_text):
        super().__init__(answer_error)
        self.answer_text = answer_text


# a message ZmAI's filter rejected, named by its place in the pair
class RefusedMessage(ValueError):
    pass


# seconds as m:ss, or h:mm:ss from an hour up
def format_duration(seconds):
    minutes, seconds = divmod(int(max(seconds, 0)), 60)
    hours, minutes = divmod(minutes, 60)
    return f"{hours}:{minutes:02d}:{seconds:02d}" if hours else f"{minutes}:{seconds:02d}"


# sleeps with a countdown redrawn every second on a terminal, a single line otherwise
def wait_with_countdown(wait_seconds, reason):
    if not sys.stdout.isatty():
        print(f"  waiting {wait_seconds:.0f}s {reason}", flush=True)
        time.sleep(wait_seconds)
        return
    wait_end = time.time() + wait_seconds
    while (seconds_left := wait_end - time.time()) > 0:
        print(f"\r\033[K  waiting {seconds_left:.0f}s {reason}", end="", flush=True)
        time.sleep(min(seconds_left, 1.0))
    print("\r\033[K", end="", flush=True)


# red failure banner on stderr, with the end of the raw ZmAI answer when there is one
def print_failure(failure_text, answer_text=""):
    red_start, red_end = ("\033[1;31m", "\033[0m") if sys.stderr.isatty() else ("", "")
    print(f"\n{red_start}{'!' * 60}\n{failure_text}{red_end}", file=sys.stderr)
    if answer_text:
        print(f"  answer ended with: …{answer_text[-FAILURE_ANSWER_TAIL_CHARS:]}", file=sys.stderr)
    print(f"{red_start}{'!' * 60}{red_end}\n", file=sys.stderr, flush=True)


# spaces requests to one service with a jittered delay and stops at the per-run request cap
class RequestPacer:
    def __init__(self, service_name, min_delay, delay_jitter, max_requests):
        self.service_name = service_name
        self.min_delay = min_delay
        self.delay_jitter = delay_jitter
        self.max_requests = max_requests
        # set by --fast: the first failure raises FastPaceBroken instead of backing off
        self.fail_fast = False
        self.request_count = 0
        self.last_request_time = 0.0

    # waits out the delay since the last request, raises once the run budget is spent
    def wait_turn(self):
        if self.request_count >= self.max_requests:
            raise RequestBudgetExhausted(f"{self.service_name}: {self.max_requests} requests this run")
        wait_seconds = self.last_request_time + self.min_delay + random.uniform(0, self.delay_jitter) - time.time()
        if self.last_request_time and wait_seconds > 0:
            wait_with_countdown(wait_seconds, f"before the next {self.service_name} request")
        self.request_count += 1
        self.last_request_time = time.time()

    # sleeps after a failed request: Retry-After when given, else a doubling backoff
    def back_off(self, attempt, retry_after_header=None):
        backoff_seconds = BACKOFF_BASE_DELAY * 2 ** attempt
        if retry_after_header and retry_after_header.isdigit():
            backoff_seconds = max(backoff_seconds, float(retry_after_header))
        wait_with_countdown(backoff_seconds + random.uniform(0, self.delay_jitter), f"{self.service_name} backing off")
        self.last_request_time = time.time()


zmai_pacer = RequestPacer("ZmAI", ZMAI_MIN_DELAY, ZMAI_DELAY_JITTER, ZMAI_MAX_REQUESTS_PER_RUN)
crta_pacer = RequestPacer("crta.rs", CRTA_MIN_DELAY, CRTA_DELAY_JITTER, CRTA_MAX_REQUESTS_PER_RUN)


# counts finished stop and personality pairs and estimates the time left from the measured pace
class RunProgress:
    # guessed ZmAI answer time until real pairs are measured
    ASSUMED_ANSWER_SECONDS = 20.0

    def __init__(self, total_pairs, zmai_requests_per_pair):
        self.total_pairs = total_pairs
        self.zmai_requests_per_pair = zmai_requests_per_pair
        self.finished_pairs = 0
        self.start_time = time.time()
        self.pairs_start_time = None

    # time left: remaining pairs at the measured pace, capped by the ZmAI requests the run still allows
    def estimate_seconds_left(self):
        remaining_pairs = self.total_pairs - self.finished_pairs
        remaining_requests = zmai_pacer.max_requests - zmai_pacer.request_count
        if self.finished_pairs and zmai_pacer.request_count:
            pairs_seconds = time.time() - self.pairs_start_time
            seconds_per_pair = pairs_seconds / self.finished_pairs
            seconds_per_request = pairs_seconds / zmai_pacer.request_count
        else:
            seconds_per_request = zmai_pacer.min_delay + zmai_pacer.delay_jitter / 2 + self.ASSUMED_ANSWER_SECONDS
            seconds_per_pair = seconds_per_request * self.zmai_requests_per_pair
        return min(remaining_pairs * seconds_per_pair, remaining_requests * seconds_per_request)

    # status line printed before each pair
    def describe_next_pair(self, stop_name, personality):
        if self.pairs_start_time is None:
            self.pairs_start_time = time.time()
        return (f"[{self.finished_pairs + 1}/{self.total_pairs}] {stop_name} / {personality}"
                f" · elapsed {format_duration(time.time() - self.start_time)}"
                f" · about {format_duration(self.estimate_seconds_left())} left")


# collects the visible title and paragraph text of an article page
class ArticleTextParser(HTMLParser):
    TEXT_TAGS = {"h1", "h2", "h3", "p", "li"}
    SKIPPED_TAGS = {"script", "style", "nav", "header", "footer", "form"}

    def __init__(self):
        super().__init__()
        self.paragraphs = []
        self.title = ""
        self._open_text_tag = None
        self._skipped_depth = 0
        self._text_parts = []

    def handle_starttag(self, tag, attrs):
        if tag in self.SKIPPED_TAGS:
            self._skipped_depth += 1
        elif tag in self.TEXT_TAGS and not self._skipped_depth:
            self._open_text_tag = tag
            self._text_parts = []

    def handle_endtag(self, tag):
        if tag in self.SKIPPED_TAGS:
            self._skipped_depth = max(self._skipped_depth - 1, 0)
        elif tag == self._open_text_tag:
            paragraph_text = " ".join("".join(self._text_parts).split())
            if tag == "h1" and not self.title:
                self.title = paragraph_text
            elif len(paragraph_text) > 30:
                self.paragraphs.append(paragraph_text)
            self._open_text_tag = None

    def handle_data(self, data):
        if self._open_text_tag and not self._skipped_depth:
            self._text_parts.append(data)


# lowercase text without diacritics, for the topic patterns
def to_match_text(text):
    text = text.lower().replace("đ", "dj").replace("-", " ")
    return "".join(char for char in unicodedata.normalize("NFD", text) if unicodedata.category(char) != "Mn")


# fetches one crta.rs page politely; a Cloudflare block or 403 stops crta for this run, never retried around
def fetch_crta_page(url):
    for attempt in range(MAX_ATTEMPTS):
        crta_pacer.wait_turn()
        page_request = urllib.request.Request(url, headers={"User-Agent": CRTA_USER_AGENT})
        try:
            with urllib.request.urlopen(page_request, timeout=60) as response:
                page_html = response.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if error.code in RETRYABLE_HTTP_CODES and attempt < MAX_ATTEMPTS - 1:
                crta_pacer.back_off(attempt, error.headers.get("Retry-After"))
                continue
            raise ServiceBlocked(f"crta.rs answered {error.code} for {url}")
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt < MAX_ATTEMPTS - 1:
                crta_pacer.back_off(attempt)
                continue
            raise ServiceBlocked(f"crta.rs unreachable: {error}")
        if any(marker in page_html for marker in CLOUDFLARE_BLOCK_MARKERS):
            raise ServiceBlocked(f"crta.rs answered with a Cloudflare block for {url}")
        return page_html
    return None


# article slugs from the Q&A listing pages whose slug names a voting stop, cached for a week
def list_crta_article_slugs():
    listing_cache_path = CRTA_CACHE_DIR / "listing.json"
    if listing_cache_path.exists() and time.time() - listing_cache_path.stat().st_mtime < CRTA_LISTING_MAX_AGE:
        return json.loads(listing_cache_path.read_text(encoding="utf-8"))

    robots_parser = urllib.robotparser.RobotFileParser(CRTA_HOME_URL + "robots.txt")
    crta_pacer.wait_turn()
    robots_parser.read()
    # a blocked robots.txt reads as disallow all, which must not be cached as an empty listing
    if robots_parser.disallow_all:
        raise ServiceBlocked("crta.rs robots.txt unreachable or disallows crawling")
    article_slugs = []
    for page_number in range(1, CRTA_QA_MAX_LISTING_PAGES + 1):
        listing_url = CRTA_QA_LISTING_URL if page_number == 1 else f"{CRTA_QA_LISTING_URL}page/{page_number}/"
        if not robots_parser.can_fetch(CRTA_USER_AGENT, listing_url):
            break
        listing_html = fetch_crta_page(listing_url)
        if listing_html is None:
            break
        page_slugs = [slug for slug in dict.fromkeys(CRTA_ARTICLE_LINK_PATTERN.findall(listing_html))
                      if slug not in CRTA_NON_ARTICLE_SLUGS and slug not in article_slugs]
        if not page_slugs:
            break
        article_slugs.extend(page_slugs)

    stop_slugs = [slug for slug in article_slugs
                  if any(pattern.search(to_match_text(slug)) for pattern in TOPIC_PATTERNS.values())]
    listing_cache_path.write_text(json.dumps(stop_slugs, ensure_ascii=False, indent=2), encoding="utf-8")
    return stop_slugs


# brings missing Q&A articles into the cache; stops quietly when crta.rs blocks, the cache still serves
def refresh_crta_cache():
    CRTA_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        for article_slug in list_crta_article_slugs():
            if (CRTA_CACHE_DIR / f"{article_slug}.html").exists():
                continue
            article_html = fetch_crta_page(f"{CRTA_HOME_URL}{article_slug}/")
            if article_html:
                (CRTA_CACHE_DIR / f"{article_slug}.html").write_text(article_html, encoding="utf-8")
    except (ServiceBlocked, RequestBudgetExhausted) as reason:
        print(f"crta.rs skipped: {reason}")
        print(f"  pages saved from a browser into {CRTA_CACHE_DIR} are used instead")


# Q&A paragraphs about each stop, from every cached article, most relevant articles first
def collect_crta_excerpts():
    articles = []
    for article_path in sorted(CRTA_CACHE_DIR.glob("*.html")):
        article_parser = ArticleTextParser()
        article_parser.feed(article_path.read_text(encoding="utf-8", errors="replace"))
        articles.append(article_parser)

    excerpts_by_topic = {}
    for topic, topic_pattern in TOPIC_PATTERNS.items():
        ranked_articles = []
        for article in articles:
            matching_paragraphs = [paragraph for paragraph in article.paragraphs
                                   if topic_pattern.search(to_match_text(paragraph))]
            if matching_paragraphs:
                ranked_articles.append((len(matching_paragraphs), article.title, matching_paragraphs))
        ranked_articles.sort(key=lambda ranked_article: -ranked_article[0])

        excerpt_text = ""
        for _, article_title, matching_paragraphs in ranked_articles:
            article_excerpt = f"### {article_title}\n" + "\n".join(matching_paragraphs) + "\n\n"
            if len(excerpt_text) + len(article_excerpt) > CRTA_EXCERPT_LIMIT:
                break
            excerpt_text += article_excerpt
        excerpts_by_topic[topic] = excerpt_text.strip()
    return excerpts_by_topic


# copy of a dialogue without answer points, for the points-free stage 1
def without_scores(dialogue):
    return {node_id: {**node, "choices": [{key: value for key, value in choice.items() if key != "score"}
                                          for choice in node["choices"]]} if "choices" in node else node
            for node_id, node in dialogue.items()}


# "Deo 1" of ZmAI_dialogues.md: the task, election rules and scenarios; its structure samples stay out, the stop samples show it
def read_prompt_rules():
    rules_markdown = PROMPT_RULES_PATH.read_text(encoding="utf-8")
    rules_start = rules_markdown.index("# Deo 1: Pravila za prompt")
    rules_text = rules_markdown[rules_start:rules_markdown.index("# Deo 2: Rezultat (JSON)")].strip().removesuffix("---").strip()
    return re.sub(r"(?ms)^## Struktura dijaloga \(uzorak\)\n.*?(?=^## |\Z)", "", rules_text).strip()


# {"## heading": text of its ~~~ block} of ZmAI_prompts.md, with tones and answer levels split out
def read_zmai_prompts():
    prompts_markdown = ZMAI_PROMPTS_PATH.read_text(encoding="utf-8")
    prompt_blocks = dict(re.findall(r"(?ms)^## (.+?)\n.*?^~~~\n(.*?)\n~~~$", prompts_markdown))
    level_lines = re.findall(r"(?m)^([+-]\d+): (.+)$", prompt_blocks["Nivoi odgovora"])
    return {
        "dialogue_request": string.Template(prompt_blocks["Upit za dijalog"]),
        "tones": {heading.removeprefix("Ton: "): text for heading, text in prompt_blocks.items() if heading.startswith("Ton: ")},
        "no_crta_material": prompt_blocks["Bez materijala Crte"],
        "rating_request": string.Template(prompt_blocks["Upit za ocenu"]),
        "answer_levels": {int(level): meaning for level, meaning in level_lines},
        "answer_levels_text": prompt_blocks["Nivoi odgovora"],
        "correction_request": string.Template(prompt_blocks["Ispravka odgovora"]),
        "prompt_part": string.Template(prompt_blocks["Deo upita"]),
        "last_prompt_part": string.Template(prompt_blocks["Poslednji deo upita"]),
        "prompt_rules": read_prompt_rules(),
    }


# {file stem: dialogue} of every content dialogue
def read_content_dialogues():
    return {dialogue_path.stem: json.loads(dialogue_path.read_text(encoding="utf-8-sig"))
            for dialogue_path in sorted(CONTENT_DIR.glob("voter_*.json"))}


# mirrors DialogTree.find_data_error, plus speakers, loops and, with points required, both positive and negative answers
def find_dialogue_error(dialogue, require_points):
    if not isinstance(dialogue, dict) or not isinstance(dialogue.get("root"), dict):
        return 'missing "root" node'
    for node_id, node in dialogue.items():
        if not isinstance(node, dict) or not isinstance(node.get("text"), str):
            return f'node "{node_id}" needs a "text" string'
        if node.get("speaker") not in ("LEFT", "RIGHT"):
            return f'node "{node_id}" needs "speaker" LEFT or RIGHT'
        if not node["text"].rstrip().endswith(SENTENCE_ENDINGS):
            return f'node "{node_id}" text is empty or cut off'
        if node["text"].lstrip().startswith(("[ANG]", "[POL]")):
            return f'node "{node_id}" keeps an [ANG]/[POL] tag'
        if "choices" in node:
            choices = node["choices"]
            if not isinstance(choices, list) or not choices:
                return f'node "{node_id}" has an empty or invalid "choices"'
            for choice in choices:
                if not isinstance(choice, dict) or not isinstance(choice.get("text"), str) \
                        or not isinstance(choice.get("explanation"), str):
                    return f'node "{node_id}" has a choice without text or explanation'
                if not all(choice[text_key].rstrip().endswith(SENTENCE_ENDINGS) for text_key in ("text", "explanation")):
                    return f'node "{node_id}" has a choice text or explanation empty or cut off'
                score = choice.get("score")
                if require_points and (isinstance(score, bool) or not isinstance(score, (int, float))):
                    return f'node "{node_id}" has a choice without score'
            if require_points and not any(choice["score"] > 0 for choice in choices):
                return f'node "{node_id}" has no correct answer'
            next_ids = [choice.get("next", "") for choice in choices]
        else:
            next_ids = [node.get("next", "")]
        for next_id in next_ids:
            if not isinstance(next_id, str) or (next_id and next_id not in dialogue):
                return f'node "{node_id}" points to unknown node "{next_id}"'

    visited_ids = set()
    node_path = ["root"]
    while node_path:
        node_id = node_path.pop()
        if node_id in visited_ids:
            return f'node "{node_id}" is reached twice'
        visited_ids.add(node_id)
        node = dialogue[node_id]
        node_path.extend(choice["next"] for choice in node.get("choices", []) if choice.get("next"))
        if node.get("next"):
            node_path.append(node["next"])
    unreached_ids = set(dialogue) - visited_ids
    if unreached_ids:
        return f'nodes {sorted(unreached_ids)} are never reached from "root"'
    if require_points and not any(choice["score"] < 0 for node in dialogue.values() for choice in node.get("choices", [])):
        return "no answer has negative points"
    return ""


# first JSON object in a ZmAI answer, fenced or not
def extract_json(answer_text):
    fenced_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", answer_text, re.DOTALL)
    json_text = fenced_match.group(1) if fenced_match else answer_text[answer_text.find("{"):answer_text.rfind("}") + 1]
    return json.loads(json_text)


# asks ZmAI one question over its stream endpoint, returns (answer, thread_id)
def ask_zmai(question, thread_id):
    request_body = json.dumps({"message": question, "assistant_id": ZMAI_ASSISTANT_ID, "thread_id": thread_id}).encode()
    zmai_request = urllib.request.Request(ZMAI_API_URL, data=request_body, headers=ZMAI_REQUEST_HEADERS)
    answer_parts = []

    with urllib.request.urlopen(zmai_request, timeout=120) as response:
        for raw_line in response:
            stream_line = raw_line.decode("utf-8").strip()
            if not stream_line.startswith("data:"):
                continue

            stream_event = json.loads(stream_line[5:])
            if stream_event["type"] == "thread_id":
                thread_id = stream_event["thread_id"]
            elif stream_event["type"] == "delta":
                answer_parts.append(stream_event["delta"])
            elif stream_event["type"] == "error":
                raise RuntimeError(stream_event.get("error"))

    return "".join(answer_parts), thread_id


# asks ZmAI with pacing and backoff; 403 or repeated failures stop the run, a filtered message fails only its pair
def ask_zmai_politely(question, thread_id, message_label):
    for attempt in range(MAX_ATTEMPTS):
        zmai_pacer.wait_turn()
        try:
            return ask_zmai(question, thread_id)
        except urllib.error.HTTPError as error:
            error_body = error.read().decode("utf-8", errors="replace")[:ERROR_BODY_CHARS]
            if error.code == REFUSED_MESSAGE_HTTP_CODE:
                raise RefusedMessage(f"ZmAI refused {message_label} with {error.code}: {error_body}"
                                     f"\n  refused message began with: {question[:REFUSED_MESSAGE_HEAD_CHARS]}")
            # a refused request is refused again at any pace, so it never restarts the run
            if error.code not in RETRYABLE_HTTP_CODES:
                raise ServiceBlocked(f"ZmAI refused the request with {error.code}: {error_body}")
            if zmai_pacer.fail_fast:
                raise FastPaceBroken(f"ZmAI answered {error.code}: {error_body}")
            if attempt == MAX_ATTEMPTS - 1:
                raise ServiceBlocked(f"ZmAI answered {error.code}: {error_body}")
            zmai_pacer.back_off(attempt, error.headers.get("Retry-After"))
        except (urllib.error.URLError, TimeoutError, RuntimeError, json.JSONDecodeError) as error:
            if zmai_pacer.fail_fast:
                raise FastPaceBroken(f"ZmAI failed: {error}")
            if attempt == MAX_ATTEMPTS - 1:
                raise ServiceBlocked(f"ZmAI failed: {error}")
            zmai_pacer.back_off(attempt)
    raise ServiceBlocked("ZmAI kept failing")


# cuts a prompt into parts of at most part_limit characters: at sections first, then paragraphs, then anywhere
def split_prompt(prompt_text, part_limit):
    prompt_pieces = []
    for section_text in re.split(r"(?m)^(?=#{1,3} )", prompt_text):
        if len(section_text) <= part_limit:
            prompt_pieces.append(section_text)
            continue
        for paragraph_text in re.split(r"(?<=\n\n)", section_text):
            prompt_pieces.extend(paragraph_text[piece_start:piece_start + part_limit]
                                 for piece_start in range(0, len(paragraph_text), part_limit))

    prompt_parts = [""]
    for prompt_piece in prompt_pieces:
        if len(prompt_parts[-1]) + len(prompt_piece) > part_limit:
            prompt_parts.append("")
        prompt_parts[-1] += prompt_piece
    return [part_text.strip() for part_text in prompt_parts if part_text.strip()]


# characters left for prompt text in one message once the part wording is added
def prompt_part_limit(zmai_prompts):
    wrapper_lengths = [len(part_template.substitute(part_index=99, part_count=99, part_text=""))
                       for part_template in (zmai_prompts["prompt_part"], zmai_prompts["last_prompt_part"])]
    return ZMAI_MAX_MESSAGE_CHARS - max(wrapper_lengths)


# ZmAI messages a prompt takes: one when it fits, else one per part
def count_zmai_messages(question, zmai_prompts):
    if len(question) <= ZMAI_MAX_MESSAGE_CHARS:
        return 1
    return len(split_prompt(question, prompt_part_limit(zmai_prompts)))


# sends a prompt too long for one message as numbered parts in one thread, returns the answer to the last part
def ask_zmai_in_parts(question, thread_id, zmai_prompts, stage_label):
    if len(question) <= ZMAI_MAX_MESSAGE_CHARS:
        return ask_zmai_politely(question, thread_id, stage_label)
    prompt_parts = split_prompt(question, prompt_part_limit(zmai_prompts))
    for part_index, part_text in enumerate(prompt_parts, 1):
        part_template = zmai_prompts["last_prompt_part" if part_index == len(prompt_parts) else "prompt_part"]
        part_message = part_template.substitute(part_index=part_index, part_count=len(prompt_parts), part_text=part_text)
        answer_text, thread_id = ask_zmai_politely(part_message, thread_id, f"{stage_label} part {part_index}/{len(prompt_parts)}")
    return answer_text, thread_id


# asks for JSON and gives ZmAI one correction in the same thread when the answer does not parse or validate
def ask_zmai_for_json(question, thread_id, find_answer_error, zmai_prompts, stage_label):
    correction_request = zmai_prompts["correction_request"]
    answer_text, thread_id = ask_zmai_in_parts(question, thread_id, zmai_prompts, stage_label)
    for correction_round in range(2):
        try:
            parsed_answer = extract_json(answer_text)
            answer_error = find_answer_error(parsed_answer)
        except (ValueError, json.JSONDecodeError) as error:
            parsed_answer, answer_error = None, f"JSON se ne može pročitati ({error})"
        if not answer_error:
            return parsed_answer, thread_id
        if correction_round == 1:
            break
        correction_question = correction_request.substitute(answer_error=answer_error)
        answer_text, thread_id = ask_zmai_politely(correction_question, thread_id, f"{stage_label} correction")
    raise UnusableAnswer(answer_error, answer_text)


# stage 1 prompt: rules, the stop, its existing dialogues as compact samples without points and Crta Q&A
def build_dialogue_prompt(zmai_prompts, stop_info, personality, sample_dialogues, covered_roots, crta_excerpt):
    sample_text = "\n\n".join(f"### {name}.json\n```json\n{json.dumps(without_scores(dialogue), ensure_ascii=False, separators=(',', ':'))}\n```"
                              for name, dialogue in sample_dialogues.items())
    covered_text = "\n".join(f"- {root_text}" for root_text in covered_roots)
    return zmai_prompts["dialogue_request"].substitute(
        prompt_rules=zmai_prompts["prompt_rules"],
        stop_title=stop_info["title"],
        stop_content=stop_info["content"],
        personality=personality,
        tone=zmai_prompts["tones"][personality],
        sample_dialogues=sample_text,
        covered_scenarios=covered_text,
        crta_material=crta_excerpt or zmai_prompts["no_crta_material"],
    )


# stage 2 prompt: one level per answer, judged by how grave the transgression is
def build_rating_prompt(zmai_prompts, dialogue):
    return zmai_prompts["rating_request"].substitute(
        answer_levels=zmai_prompts["answer_levels_text"],
        dialogue=json.dumps(dialogue, ensure_ascii=False, indent=2),
    )


# error text when the levels do not cover every answer with an allowed level, else empty
def find_levels_error(dialogue, answer_levels, allowed_levels):
    if not isinstance(answer_levels, dict):
        return "očekuje se JSON objekat"
    for node_id, node in dialogue.items():
        if "choices" not in node:
            continue
        node_levels = answer_levels.get(node_id)
        if not isinstance(node_levels, list) or len(node_levels) != len(node["choices"]):
            return f'čvor "{node_id}" treba {len(node["choices"])} nivoa'
        if any(level not in allowed_levels for level in node_levels):
            return f'čvor "{node_id}" ima nivo van skale'
        if not any(level > 0 for level in node_levels):
            return f'čvor "{node_id}" nema nijedan ispravan odgovor'
    if not any(level < 0 for node_id, node in dialogue.items() if "choices" in node for level in answer_levels[node_id]):
        return "nijedan odgovor nema negativan nivo"
    return ""


# expected points per answer screen of a 75% accurate player: right picks among positive answers, wrong among negative
def expected_answer_points(choice_scores):
    positive_scores = [score for score in choice_scores if score > 0]
    negative_scores = [score for score in choice_scores if score <= 0]
    if not negative_scores:
        return sum(positive_scores) / len(positive_scores)
    return AVERAGE_PLAYER_ACCURACY * sum(positive_scores) / len(positive_scores) \
        + (1 - AVERAGE_PLAYER_ACCURACY) * sum(negative_scores) / len(negative_scores)


# choice score lists of every answer screen in the dialogues
def answer_screens(dialogues):
    return [[choice["score"] for choice in node["choices"]]
            for dialogue in dialogues for node in dialogue.values() if "choices" in node]


# score unit and answers per run implied by the content the targets were tuned on, frozen on first run
def load_calibration(content_dialogues, best_answer_level):
    if CALIBRATION_PATH.exists():
        return json.loads(CALIBRATION_PATH.read_text(encoding="utf-8"))
    screens = answer_screens(content_dialogues.values())
    best_answer_points = max(max(choice_scores) for choice_scores in screens)
    average_answer_points = sum(map(expected_answer_points, screens)) / len(screens)
    calibration = {
        "score_unit": best_answer_points / best_answer_level,
        "best_answer_points": best_answer_points,
        "max_run_answers": TARGET_MAX_RUN_POINTS / best_answer_points,
        "average_run_answers": TARGET_AVERAGE_RUN_POINTS / average_answer_points,
    }
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    CALIBRATION_PATH.write_text(json.dumps(calibration, indent=2), encoding="utf-8")
    return calibration


# points of a level, rounded to thousands like the existing content; negatives never round to zero
def level_points(level, score_unit, negative_scale):
    if level > 0:
        return int(round(level * score_unit, -3))
    return min(int(round(level * score_unit * negative_scale, -3)), -1000)


# writes the levels into the drafts as points, scaling new negatives so the whole pool holds the average target
def score_drafts(drafts, content_dialogues, calibration):
    score_unit = calibration["score_unit"]
    target_answer_points = TARGET_AVERAGE_RUN_POINTS / calibration["average_run_answers"]
    content_screens = answer_screens(content_dialogues.values())
    draft_level_screens = [node_levels for draft in drafts for node_levels in draft["levels"].values()]
    screen_count = len(content_screens) + len(draft_level_screens)

    content_points_sum = sum(map(expected_answer_points, content_screens))
    draft_positive_sum = draft_negative_sum = 0.0
    for node_levels in draft_level_screens:
        positive_points = [level_points(level, score_unit, 1.0) for level in node_levels if level > 0]
        negative_points = [level * score_unit for level in node_levels if level < 0]
        positive_weight = AVERAGE_PLAYER_ACCURACY if negative_points else 1.0
        draft_positive_sum += positive_weight * sum(positive_points) / len(positive_points)
        if negative_points:
            draft_negative_sum += (1 - AVERAGE_PLAYER_ACCURACY) * sum(negative_points) / len(negative_points)

    negative_scale = 1.0
    if draft_negative_sum:
        negative_scale = (screen_count * target_answer_points - content_points_sum - draft_positive_sum) / draft_negative_sum
        negative_scale = min(max(negative_scale, NEGATIVE_SCALE_LIMITS[0]), NEGATIVE_SCALE_LIMITS[1])

    for draft in drafts:
        for node_id, node_levels in draft["levels"].items():
            for choice, level in zip(draft["dialogue"][node_id]["choices"], node_levels):
                choice["score"] = level_points(level, score_unit, negative_scale)
    return negative_scale


# next free file index of a stop and personality in content/
def next_dialogue_index(topic, personality):
    used_indexes = [int(match.group(3)) for match in map(DIALOGUE_FILENAME_PATTERN.fullmatch, (path.name for path in CONTENT_DIR.glob("voter_*.json")))
                    if match and match.group(1) == topic and match.group(2) == personality]
    return max(used_indexes, default=0) + 1


# scores every finished draft, adds it to content/ as a new file and prints where the pool points land
def publish_drafts(calibration):
    draft_paths = sorted(DRAFTS_DIR.glob("*.json")) if DRAFTS_DIR.exists() else []
    if not draft_paths:
        print("No new dialogues to add")
        return 0
    drafts = [json.loads(draft_path.read_text(encoding="utf-8")) for draft_path in draft_paths]
    content_dialogues = read_content_dialogues()
    negative_scale = score_drafts(drafts, content_dialogues, calibration)

    for draft_path, draft in zip(draft_paths, drafts):
        dialogue_error = find_dialogue_error(draft["dialogue"], require_points=True)
        if dialogue_error:
            print(f"Dropped draft {draft_path.name}: {dialogue_error}")
            draft_path.unlink()
            continue
        dialogue_name = DIALOGUE_FILENAME.format(topic=draft["topic"], personality=draft["personality"],
                                                 index=next_dialogue_index(draft["topic"], draft["personality"]))
        dialogue_json = json.dumps(draft["dialogue"], ensure_ascii=False, indent=2) + "\n"
        (CONTENT_DIR / dialogue_name).write_text(dialogue_json, encoding="utf-8")
        draft_path.unlink()
        print(f"Added {dialogue_name}")

    screens = answer_screens(read_content_dialogues().values())
    average_answer_points = sum(map(expected_answer_points, screens)) / len(screens)
    best_answer_points = max(max(choice_scores) for choice_scores in screens)
    print(f"Negative points scale of the new dialogues: {negative_scale:.2f}")
    print(f"Projected average run ({AVERAGE_PLAYER_ACCURACY:.0%} accuracy): {calibration['average_run_answers'] * average_answer_points:,.0f}")
    print(f"Projected theoretical maximum: {calibration['max_run_answers'] * best_answer_points:,.0f}")
    return len(list(CONTENT_DIR.glob("voter_*.json"))) - len(content_dialogues)


# the personality's newest dialogues of a stop as samples, and every scenario of the stop already in content or drafts
def gather_stop_context(topic, personality, content_dialogues):
    stop_dialogues = {name: dialogue for name, dialogue in content_dialogues.items() if f"voter_{topic}_dialog_" in name}
    personality_names = sorted(name for name in stop_dialogues if name.split("_")[-2] == personality)
    sample_dialogues = {name: stop_dialogues[name] for name in personality_names[-SAMPLE_DIALOGUES_PER_PROMPT:]}
    covered_roots = [dialogue["root"]["text"] for dialogue in stop_dialogues.values()]
    covered_roots += [json.loads(path.read_text(encoding="utf-8"))["dialogue"]["root"]["text"]
                      for path in DRAFTS_DIR.glob(f"{topic}_*.json")]
    return sample_dialogues, covered_roots


# ZmAI requests of one pair before any is measured: the first pair's stage 1 parts plus rating one of its samples
def estimate_zmai_requests_per_pair(zmai_prompts, stop_infos, content_dialogues, crta_excerpts):
    stop_name, personality = DIALOGUE_STOPS[0], next(iter(zmai_prompts["tones"]))
    sample_dialogues, covered_roots = gather_stop_context(stop_name.lower(), personality, content_dialogues)
    dialogue_prompt = build_dialogue_prompt(zmai_prompts, stop_infos[stop_name], personality, sample_dialogues,
                                            covered_roots, crta_excerpts[stop_name.lower()])
    rating_prompt = build_rating_prompt(zmai_prompts, without_scores(next(iter(sample_dialogues.values()), {})))
    return count_zmai_messages(dialogue_prompt, zmai_prompts) + count_zmai_messages(rating_prompt, zmai_prompts)


# stage 1 and 2 for one stop and personality, saved as a draft so an interrupted run loses nothing
def create_draft(zmai_prompts, stop_name, stop_info, personality, content_dialogues, crta_excerpt):
    topic = stop_name.lower()
    sample_dialogues, covered_roots = gather_stop_context(topic, personality, content_dialogues)

    dialogue_prompt = build_dialogue_prompt(zmai_prompts, stop_info, personality, sample_dialogues, covered_roots, crta_excerpt)
    dialogue, _ = ask_zmai_for_json(dialogue_prompt, None,
                                    lambda answer: find_dialogue_error(answer, require_points=False),
                                    zmai_prompts, "stage 1")
    dialogue = without_scores(dialogue)
    root_text = dialogue["root"]["text"]
    if any(difflib.SequenceMatcher(None, root_text, covered_root).ratio() > DUPLICATE_ROOT_RATIO for covered_root in covered_roots):
        print(f"  skipped, repeats a covered scenario: {root_text}")
        return False

    # a new thread, so the rating never sits on top of the long stage 1 context
    answer_levels, _ = ask_zmai_for_json(build_rating_prompt(zmai_prompts, dialogue), None,
                                         lambda answer: find_levels_error(dialogue, answer, zmai_prompts["answer_levels"]),
                                         zmai_prompts, "rating")
    answer_levels = {node_id: node_levels for node_id, node_levels in answer_levels.items() if "choices" in dialogue.get(node_id, {})}
    draft = {"topic": topic, "personality": personality, "dialogue": dialogue, "levels": answer_levels}
    draft_path = DRAFTS_DIR / f"{topic}_{personality}_{int(time.time())}.json"
    draft_path.write_text(json.dumps(draft, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  drafted: {root_text}")
    return True


def main():
    argument_parser = argparse.ArgumentParser(description="Adds new ZmAI-written dialogues to content/, never changing existing ones.")
    argument_parser.add_argument("--per-pair", type=int, default=1, help="new dialogues per stop and personality (default 1)")
    argument_parser.add_argument("--fast", action="store_true",
                                 help=f"ZmAI requests {ZMAI_FAST_MIN_DELAY:.0f}-{ZMAI_FAST_MIN_DELAY + ZMAI_FAST_DELAY_JITTER:.0f}s apart instead of"
                                      f" {ZMAI_MIN_DELAY:.0f}-{ZMAI_MIN_DELAY + ZMAI_DELAY_JITTER:.0f}s; the first ZmAI failure restarts the run at the normal pace")
    argument_parser.add_argument("--resume-from", type=int, default=0, help="stop and personality pair to start from, set by the --fast restart")
    arguments = argument_parser.parse_args()
    if arguments.fast:
        zmai_pacer.min_delay, zmai_pacer.delay_jitter, zmai_pacer.fail_fast = ZMAI_FAST_MIN_DELAY, ZMAI_FAST_DELAY_JITTER, True

    DRAFTS_DIR.mkdir(parents=True, exist_ok=True)
    content_dialogues = read_content_dialogues()
    zmai_prompts = read_zmai_prompts()
    calibration = load_calibration(content_dialogues, max(zmai_prompts["answer_levels"]))
    stop_infos = json.loads(INFO_TEXTS_PATH.read_text(encoding="utf-8"))

    refresh_crta_cache()
    crta_excerpts = collect_crta_excerpts()

    run_pairs = [(stop_name, personality) for stop_name in DIALOGUE_STOPS
                  for personality in zmai_prompts["tones"] for _ in range(arguments.per_pair)][arguments.resume_from:]
    run_progress = RunProgress(len(run_pairs),
                               estimate_zmai_requests_per_pair(zmai_prompts, stop_infos, content_dialogues, crta_excerpts))
    drafted_count = 0
    failure_reports = []
    fast_pace_broken = False
    try:
        for stop_name, personality in run_pairs:
            print(run_progress.describe_next_pair(stop_name, personality), flush=True)
            for draft_attempt in range(1, DRAFT_ATTEMPTS + 1):
                try:
                    drafted_count += create_draft(zmai_prompts, stop_name, stop_infos[stop_name], personality,
                                                  content_dialogues, crta_excerpts[stop_name.lower()])
                    break
                except ValueError as error:
                    pair_label = f"[{run_progress.finished_pairs + 1}/{run_progress.total_pairs}] {stop_name} / {personality}"
                    failure_reports.append(f"{pair_label}, attempt {draft_attempt}/{DRAFT_ATTEMPTS}: {error}")
                    print_failure(f"✗ FAILED {failure_reports[-1]}", getattr(error, "answer_text", ""))
                    if draft_attempt == DRAFT_ATTEMPTS:
                        print_failure(f"✗ GAVE UP {pair_label}, skipped after {DRAFT_ATTEMPTS} attempts")
            run_progress.finished_pairs += 1
    except FastPaceBroken as reason:
        print_failure(f"✗ Fast pace broke: {reason}\nStopping and restarting at the normal pace.")
        fast_pace_broken = True
    except (ServiceBlocked, RequestBudgetExhausted) as reason:
        print_failure(f"✗ Stopped asking ZmAI: {reason}")
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
    finally:
        published_count = publish_drafts(calibration)
        print(f"Done in {format_duration(time.time() - run_progress.start_time)}"
              f" · ZmAI requests {zmai_pacer.request_count}/{zmai_pacer.max_requests}"
              f" · drafted {drafted_count} · published {published_count}")
        if failure_reports:
            print_failure(f"✗ {len(failure_reports)} failed attempts this run:\n  " + "\n  ".join(failure_reports))

    if fast_pace_broken:
        restart_arguments = ["--per-pair", str(arguments.per_pair),
                             "--resume-from", str(arguments.resume_from + run_progress.finished_pairs)]
        wait_with_countdown(BACKOFF_BASE_DELAY, "before restarting at the normal pace")
        print(f"Restarting at the normal pace from pair {arguments.resume_from + run_progress.finished_pairs + 1}", flush=True)
        os.execv(sys.executable, [sys.executable, __file__, *restart_arguments])


if __name__ == "__main__":
    main()
