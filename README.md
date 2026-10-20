# Glasalica

A mobile-forst and web game about voting procedure in Serbia. Voters pass
through the stops of the voting process one by one, and every answer you give
in the dialogue system earns or costs points: following the procedure earns points,
breaking the rules costs them, and the bigger the violation, the bigger the penalty.

- [Section 1: Content](#section-1-content)
- [Section 2: Implementation](#section-2-implementation)

---

## Disclaimer

**Glasalica is a game, not a legal reference.** Its sole purpose is entertainment.
Nothing in it is a legal source, legal advice or an official interpretation of
election rules.

**AI-generated content.** The dialogues, answer explanations and points were
generated with the help of [ZmAI](https://zmai.crta.rs/), the artificial intelligence assistant of [Crta](https://crta.rs/). AI can be wrong: the
content may contain errors, inaccuracies, simplifications or outdated information.
It is provided "as is", without any warranty of accuracy, completeness or fitness
for a particular purpose.

**Check official sources.** Election rules change and depend on the type of
election. For the rules that actually apply, check the current law and the
instructions.

**No liability.** The authors are not responsible for any decision or action
taken based on the game's content.

**No endorsement.** Mentioning Crta and ZmAI credits the use of their tools as
the source of the content. It does not mean they reviewed, approved or are responsible
for the game or its content.

**Fictional characters.** All voters and situations in the game are fictional.
Any resemblance to real persons or events is coincidental.

## Thanks

Special thanks to [Crta](https://crta.rs/), whose ZmAI assistant and public [Q&A](https://crta.rs/kategorija/q_a/) about
the voting process are the source of the game's dialogues.

Also, thanks to everyone who helped build Glasalica: **Marija M.**, **Igor I.**, **Nemanja M.**, **Đorđe Đ.**, **Aleksandar Lj.**, **Andrej O.**, **Bojan V.**, **Ivana B.**, **Davor V.**, **Marko M.**, **Miloš S.**, **Nemanja L.**, **Miloš P.**, **Vladimir A.**, **Željko V.**, and all the friends and supporters of the students movement.

---

# Section 1: Content

## Where the content comes from

### The voting stops

The game follows the seven stops a voter goes through at a polling station:

1. UV lamp check — has the voter already voted
2. Identity check — ID card or passport
3. Voter register — finding the voter and their signature
4. Invisible spray on the finger
5. Handing out the ballot
6. Filling in the ballot behind the screen
7. The ballot box

### The dialogues

Every stop except the ballot box has dialogues, built from real situations and violations that happen at polling stations.

- **First dialogues** were generated with **ZmAI**, the AI assistant of [Crta](https://crta.rs/) at [zmai.crta.rs](https://zmai.crta.rs/).
- **Additional dialogues** are added by `ZmAI_updater.py` (see Section 2). It asks ZmAI
  again, using the [Crta Q&A articles](https://crta.rs/kategorija/q_a/) about the voting process as the source of facts.
- **Points** for every answer are tweaked so an average player reaches about 2,000,000 points in a run, with a theoretical maximum of 6,500,000 (no. of votes, wink, wink?).

# Section 2: Implementation

## Build scripts

The project has three separate scripts — two for dialogues, one for exporting:

| Script                  | Location                   | Purpose                                                 |
| ----------------------- | -------------------------- | ------------------------------------------------------- |
| `ZmAI_updater.py`       | `code/!project/dialogues/` | adds ZmAI-supported voter dialogues to `content/`       |
| `scramble_dialogues.py` | `code/!project/dialogues/` | packs the voter dialogues into scrambled `.bin` content |
| `export.sh`             | `code/prod/`               | headless Godot export for Android, iOS and web          |

## Running the build scripts

Add new dialogues, from `code/` (then scramble them):

```bash
cd '!project/dialogues'
./ZmAI_updater.py                # one new dialogue per stop and personality (12)
./ZmAI_updater.py --per-pair 2   # two per stop and personality (24)
```

Scramble dialogues, from `code/`:

```bash
cd '!project/dialogues'
./scramble_dialogues.py
```

Export, from `code/` — **important: close the Godot editor first**:

```bash
cd prod
./export.sh            # release: Android AAB + iOS Xcode project + web
./export.sh android    # release Android AAB only
./export.sh ios        # release iOS Xcode project only
./export.sh web        # release web build only
./export.sh debug      # debug Android AAB (no release keystore needed)
```

```bash
cd ../../../release/build/web
zip -r -FS ../blokadna-glasalica-web.zip .
# -> !project/release/build/blokadna-glasalica-web.zip
```

---

## 1. Dialogue scrambling — `scramble_dialogues.py`

### Usage

```bash
cd '!project/dialogues'
./scramble_dialogues.py
```

Needs Python 3. Can be run from any directory.

Output:

```
Scrambled 26 dialogues, version 1759262400 -> …/dialogues_content.bin (commit and push it to main to publish)
```

The script exits with an error and writes nothing if the scrambling key is missing or
any dialogue file is invalid.

### Input and output

All under `!project/dialogues/`:

| File                    | Role                                        |
| ----------------------- | ------------------------------------------- |
| `content/voter_*.json`  | **input** — one dialogue per file           |
| `dialogues_content.bin` | **output** — scrambled content for the game |

### Configuration

`code/runtime_credentials.cfg` (gitignored; copy `runtime_credentials.example.cfg`):

```ini
[dialogues]
scrambler_key="<scramble-key>"
```

Changing the scrambling key means rescrambling **and** re-exporting.

### Publishing new dialogues without a new build

Every build reads its dialogues from `https://raw.githubusercontent.com/kreativna-blokada/blokadna-glasalica/main/!project/dialogues/dialogues_content.bin`, so revised dialogues reach players as soon as the `!project/dialogues/content/voter_*.json` files are updated, the script is run, and the regenerated `dialogues_content.bin` is committed and pushed to `main`.

Builds released before this change still read `https://raw.githubusercontent.com/zeljko-vulovic/glasalica/main/dialogues.bin`; that repository stays online until those players have updated.

---

## 2. Dialogue updating — `ZmAI_updater.py`

### Usage

```bash
cd '!project/dialogues'
./ZmAI_updater.py                # one new dialogue per stop and personality (12)
./ZmAI_updater.py --per-pair 2   # two per stop and personality (24)
```

Needs Python 3 and network access. A default run takes about 25–30 minutes.
Run `scramble_dialogues.py` afterwards so the game gets the new dialogues.

Output:

```
Lamp / angry
  drafted: <opening line of the new dialogue>
…
Added voter_lamp_dialog_angry_04.json
…
Negative points scale of the new dialogues: 0.85
Projected average run (75% accuracy): 2,000,000
Projected theoretical maximum: 6,500,000
```

The script only adds files. Existing dialogues are never changed or deleted.

### How it works

The script goes through the election stops in order — `Lamp`, `ID`, `List`,
`Spray`, `Ballot`, `Booth` — and, for each stop, through both personalities,
`angry` and `polite`. For every stop and personality pair it asks ZmAI
(`zmai.crta.rs`) for one new dialogue in two stages, in the same ZmAI thread.

Everything sent to ZmAI is worded in two markdown files, so it can be changed
without touching the script: the rules in `ZmAI_dialogues.md` and the requests,
tones, level ladder and correction message in `ZmAI_prompts.md`. The script only
fills in their `$placeholders`.

**Stage 1 — writing.** ZmAI gets the `Upit za dijalog` request from
`ZmAI_prompts.md`, filled with:

- the rules from `ZmAI_dialogues.md`, section `# Deo 1: Pravila za prompt`
- the stop's title and text from `info_texts.json`
- the existing dialogues of that stop and personality, as samples of tone,
  style and approach
- the opening lines of all dialogues of that stop, as scenarios already covered
- matching paragraphs from the Crta Q&A articles (`https://crta.rs/kategorija/q_a/`),
  if any are cached

ZmAI answers with the dialogue JSON, with every score set to 0. The answer is
checked: every node needs `text` and a `LEFT`/`RIGHT` `speaker`, no `[ANG]`/`[POL]`
tags, every choice needs `text`, `explanation` and `score`, every `next` must
exist and no node may be reached twice. If the check fails, ZmAI gets one
correction request; a second failure skips the pair. A dialogue whose opening
line is too close to an existing one (over 75% similar) is skipped too.

**Stage 2 — points.** ZmAI rates every answer on the level ladder from
`ZmAI_prompts.md` (`Nivoi odgovora`), and the script
turns levels into points:

| Level   | Meaning                                        | Points            |
| ------- | ---------------------------------------------- | ----------------- |
| 10      | best answer                                    | 131,000           |
| 8, 5, 3 | correct, but less complete                     | 105,000 … 39,000  |
| −1 … −6 | wrong; the bigger the transgression, the lower | −13,000 … −79,000 |

Every choice node needs at least one correct answer and every dialogue at least
one wrong one. One level is 13,100 points, the same scale as the existing
content. The negative points of the new dialogues are then scaled (between
×0.5 and ×2) so the whole pool keeps the run targets:

- average player (75% correct answers): about **2,000,000** points per run
- theoretical maximum: **6,500,000** points per run

The run lengths behind these targets (about 49.6 answers in a maximum run, 22.3
in an average one) are measured once from the current content and frozen in
`.updater_cache/calibration.json`. Delete that file to measure again.

**Publishing.** Each finished dialogue is first saved as a draft in
`.updater_cache/drafts/`. At the end of the run — also after an error, a block
or Ctrl+C — the drafts are scored, checked again and written to `content/` under
the next free number, e.g. `voter_list_dialog_angry_06.json`.

### Not getting blocked

| Server  | Pause between requests | Requests per run |
| ------- | ---------------------- | ---------------- |
| ZmAI    | 40–60 s (random)       | 40               |
| crta.rs | 12–20 s (random)       | 40               |

- On `429` or `5xx` the script waits 2 minutes, then 4 minutes; the third failure
  stops the run.
- On `403` the script stops asking that server for the rest of the run.
- When the request limit is reached, the run stops and publishes what it has.
- crta.rs `robots.txt` is read first and respected.

### Crta sources

crta.rs is behind Cloudflare and usually answers scripted requests with `403`.
The script does not try to get around it: it stops crawling and uses the cache
instead. To give ZmAI Crta material anyway, open the Q&A articles about the
voting process in a browser, save them as `.html` and put them in
`.updater_cache/crta/`. Without any cached pages ZmAI writes from its own Crta
knowledge.

Only articles matching a stop's topic are used (e.g. lamp: UV lampa,
skeniranje; spray: sprej, prskanje; ballot: glasački listić). The article listing is cached for 7 days.

### Files

All under `!project/dialogues/`:

| File                              | Role                                            |
| --------------------------------- | ----------------------------------------------- |
| `ZmAI_dialogues.md`               | **input** — prompt rules (`Deo 1`)              |
| `ZmAI_prompts.md`                 | **input** — requests, tones, levels to ZmAI     |
| `info_texts.json`                 | **input** — the election stops                  |
| `content/voter_*.json`            | **input and output** — samples; new files added |
| `.updater_cache/crta/`            | cached Crta articles and listing                |
| `.updater_cache/drafts/`          | finished dialogues not yet published            |
| `.updater_cache/calibration.json` | frozen run-length calibration                   |

`.updater_cache/` is not in `.gitignore`.

---

## 3. Exporting — `export.sh`

### Usage

**Important: close the Godot editor first** — the script refuses to run while
the editor has the project open.

```bash
cd prod
./export.sh            # release: Android AAB + iOS Xcode project + web
./export.sh android    # release Android AAB only
./export.sh ios        # release iOS Xcode project only
./export.sh web        # release web build only
./export.sh debug      # debug Android AAB (no release keystore needed)
```

Output, in `!project/release/build/` (next to `blokadna-glasalica`):

| Target  | File                                                                     |
| ------- | ------------------------------------------------------------------------ |
| Android | `android/blokadna-glasalica.aab` (debug: `blokadna-glasalica-debug.aab`) |
| iOS     | `ios/blokadna-glasalica.xcodeproj` — archive and upload with Xcode       |
| Web     | `web/index.html` + files — must be served over HTTP                      |

Each target prints its output path, or the errors and `FAILED: <preset>` with
a non-zero exit.

### Packaging the build

After a web export, zip the build for upload, from `prod/`:

```bash
cd ../../../release/build/web
zip -r -FS ../blokadna-glasalica-web.zip .
# -> !project/release/build/blokadna-glasalica-web.zip
```

### Requirements

- Godot at `/Applications/Godot.app` with 4.6 export templates
- Android Gradle template unpacked in `code/android/build/`
- The configuration files below

### Configuration

All in `code/` unless noted.

| File                                      | In git | What it holds                                       |
| ----------------------------------------- | ------ | --------------------------------------------------- |
| `export_presets.cfg`                      | no     | the `Android`, `iOS` and `Web` presets              |
| `export_credentials.cfg`                  | no     | keystore and provisioning secrets                   |
| `runtime_credentials.cfg`                 | no     | database and dialogue settings packed into the game |
| `project.godot`                           | yes    | `config/version`                                    |
| `!project/release/export_credentials.cfg` | —      | backup copy of `export_credentials.cfg`             |

#### `export_presets.cfg`

Preset names must stay `Android`, `iOS` and `Web`. Each preset:

- exports all resources and additionally includes
  `!project/dialogues/dialogues_content.bin, runtime_credentials.cfg`
  (`include_filter`)
- Android: Gradle build, AAB, arm64 only, `package/unique_name`,
  `version/code`, `version/name`
- iOS: `application/bundle_identifier`, `application/version`,
  `application/short_version`
- Web: no threads, no extensions

**Every release** bump the versions together:

| Where           | Key                         | Rule                     |
| --------------- | --------------------------- | ------------------------ |
| Android preset  | `version/code`              | +1, must always increase |
| Android preset  | `version/name`              | e.g. `0.8.0`             |
| iOS preset      | `application/version`       | +1                       |
| iOS preset      | `application/short_version` | same as `version/name`   |
| `project.godot` | `config/version`            | same as `version/name`   |

#### `export_credentials.cfg`

```ini
[preset.0.options]
keystore/release="<path to release keystore>"
keystore/release_user="<alias>"
keystore/release_password="<password>"
```

The `[preset.1.options]` section holds the iOS provisioning profiles.

#### `runtime_credentials.cfg`

```ini
[database]
debug_release=true          ; true = release builds still use the development database
database_endpoint="https://<production-project-id>-default-rtdb.firebaseio.com"

[dialogues]
scrambler_key="<scramble-key>"
```

`export.sh` reports which database the build will use:

- `debug_release=false` → `== database: PRODUCTION` plus a reminder to lock
  the development database rules
- otherwise → `== database: development`
