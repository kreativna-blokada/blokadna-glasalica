##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Online leaderboard manager over Firebase Realtime Database
#maintainer      : Zeljko
#version         : 1.4
#===============================================================================
extends Node

const ID_BYTE_COUNT: int = 16
const PLAYER_IDENTITY: String = "user://player_identity.cfg"
#answers of finished days kept on this device, {request endpoint: {run_day, server_body}}
const STORED_ANSWERS: String = "user://leaderboard_answers.json"

#letters, digits, space, _ and -;
#must match the pattern in database.rules.json
const NAME_PATTERN: String = "^[A-Za-z0-9 _-]+$"
#child the leaderboard queries order by; indexed by .indexOn in database.rules.json
const SCORE_ORDER: String = "\"score\""
#lists only the day keys of the leaderboards, each answered as true, without their scores
const RUN_DAY_KEYS_QUERY: String = "shallow=true"
#part of the query that asks for the players above a score
const PLAYERS_ABOVE_QUERY: String = "startAt="
#the run day of a daily leaderboard endpoint, e.g. /leaderboards/20380.json or /leaderboards/20380/<player id>.json
const RUN_DAY_ENDPOINT_PATTERN: String = "/leaderboards/(\\d+)[/.]"
#days a run day must be before today to count as finished; one more than needed, as the device clock may be a day off
const FINISHED_DAY_MARGIN: int = 2
const DAYS_PER_WEEK: int = 7
const NO_RUN_DAY: int = -1

const NO_RUN_POINTS_PENDING: int = -1

const HOUR_SECONDS: int = 3600
const DAY_SECONDS: int = 86400
const MONTH_ABBREVIATIONS: PackedStringArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

#private vars
var _database_endpoint: String = ""
var _player_id: String = ""
var _username: String = ""
var _username_regex: RegEx = RegEx.create_from_string(NAME_PATTERN)
var _run_points: int = NO_RUN_POINTS_PENDING
#a run score the database turned down for the player's higher best, until the leaderboard has told the player
var _declined_points: int = NO_RUN_POINTS_PENDING
#successful GET answers by request endpoint, {msec, fetch_result, response_code, server_headers, server_body}
var _cached_answers: Dictionary[String, Dictionary] = {}
#answers of finished days, which can no longer change, loaded from STORED_ANSWERS on the first request
var _stored_answers: Dictionary = {}
var _is_stored_answers_loaded: bool = false
var _is_stored_answers_save_pending: bool = false
var _run_day_endpoint_regex: RegEx = RegEx.create_from_string(RUN_DAY_ENDPOINT_PATTERN)

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_database_endpoint = _resolve_database_endpoint()
	if _database_endpoint.is_empty():
		push_warning("LeaderboardManager._ready: no database endpoint configured, leaderboard disabled")
	_load_player_identity()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#checks whether a database endpoint is configured for this build
func is_enabled() -> bool:
	return not _database_endpoint.is_empty()

#checks whether the typed username can be used as a leaderboard key
func is_valid_username(typed_username: String) -> bool:
	var trimmed_username: String = typed_username.strip_edges()
	if trimmed_username.is_empty() or trimmed_username.length() > Configs.Leaderboard.username_length:
		return false
	return _username_regex.search(trimmed_username) != null

#returns the username the database gave this player, or an empty string
func get_username() -> String:
	return _username

#returns the random id this install stores its score under
func get_player_id() -> String:
	return _player_id

#keeps the finished run score for the leaderboard screen to submit
func set_run_points(run_points: int) -> void:
	_run_points = run_points

#returns the finished run score still waiting to be stored on the leaderboard, or NO_RUN_POINTS_PENDING
func get_run_points() -> int:
	return _run_points

#forgets the run score once the leaderboard has stored it or kept a higher one
func clear_stored_points() -> void:
	_run_points = NO_RUN_POINTS_PENDING

#keeps a run score the database turned down for a higher best, for the leaderboard to tell the player about
func set_declined_points(run_points: int) -> void:
	_declined_points = run_points

#returns the run score turned down for a higher best and forgets it, or NO_RUN_POINTS_PENDING
func take_declined_points() -> int:
	var declined_points: int = _declined_points
	_declined_points = NO_RUN_POINTS_PENDING
	return declined_points

#asks the database for the username; returns false if it is not valid, otherwise the answer
#arrives through Signals.user_saved or Signals.user_refused;
#the name the database holds for this player is read first, so a claim whose answer was lost still gets released
func claim_username(typed_username: String) -> bool:
	if not is_valid_username(typed_username):
		return false
	if not is_enabled():
		Signals.user_refused.emit(Globals.NameRefuse.Failed)
		return true

	var server_username_endpoint: String = "%s/scores/%s/username.json" % [_database_endpoint, _player_id]
	_send_request(server_username_endpoint, HTTPClient.METHOD_GET, "", _on_server_username_request_completed.bind(typed_username.strip_edges()))
	return true

#stores the score under this player's id, then on today's leaderboard; the database rules keep only a higher score;
#Signals.score_submitted reports the result once both answered
func submit_score(player_score: int) -> void:
	if not is_enabled() or _username.is_empty():
		Signals.score_submitted.emit(Globals.ScoreSubmit.Failed)
		return

	var score_endpoint: String = "%s/scores/%s.json" % [_database_endpoint, _player_id]
	var score_body: String = JSON.stringify({"score": player_score})
	_send_request(score_endpoint, HTTPClient.METHOD_PATCH, score_body, _on_score_request_completed.bind(player_score))

#returns today in whole days since 1970-01-01 shifted by Configs.Leaderboard.day_utc_offset, from the device clock
func get_today_day() -> int:
	var shifted_seconds: int = int(Time.get_unix_time_from_system()) + int(Configs.Leaderboard.day_utc_offset) * HOUR_SECONDS
	return floori(float(shifted_seconds) / DAY_SECONDS)

#lists every day holding scores in one request, newest first; the leaderboard screen picks the days its tabs look back for;
#they arrive through Signals.run_days_fetched tagged with fetch_key
func fetch_run_days(fetch_key: String) -> void:
	if not is_enabled():
		Signals.run_days_fetched.emit(fetch_key, false, [] as Array[int])
		return

	var run_day_keys_endpoint: String = "%s/leaderboards.json?%s" % [_database_endpoint, RUN_DAY_KEYS_QUERY]
	_send_request(run_day_keys_endpoint, HTTPClient.METHOD_GET, "", _on_run_days_request_completed.bind(fetch_key))

#fetches the best Configs.Leaderboard.top_count scores of the given run days, each player once with their best score of those days;
#without run days fetches the best all-time scores; the result arrives through Signals.ranks_fetched tagged with fetch_key
func fetch_rankings(fetch_key: String, run_days: Array[int] = []) -> void:
	if not is_enabled():
		Signals.ranks_fetched.emit(fetch_key, false, [] as Array[Dictionary])
		return

	var top_query: String = "orderBy=%s&limitToLast=%d" % [SCORE_ORDER.uri_encode(), Configs.Leaderboard.top_count]
	var rankings_fetch: Dictionary = {"fetch_key": fetch_key, "pending_count": maxi(run_days.size(), 1), "is_failed": false, "best_entries": {}}
	for score_endpoint in _get_score_endpoints(run_days):
		_send_request("%s?%s" % [score_endpoint, top_query], HTTPClient.METHOD_GET, "", _on_rankings_request_completed.bind(rankings_fetch))

#finds this player's best score of the given run days, or all-time without run days, then counts the players above it
#up to rank_count_cap on each leaderboard; the result arrives through Signals.player_standing_fetched tagged with fetch_key
func fetch_player_standing(fetch_key: String, rank_count_cap: int, run_days: Array[int] = []) -> void:
	if not is_enabled():
		Signals.player_standing_fetched.emit(fetch_key, false, {})
		return

	var score_endpoints: PackedStringArray = _get_score_endpoints(run_days)
	var standing_fetch: Dictionary = {"fetch_key": fetch_key, "pending_count": score_endpoints.size(), "is_failed": false, "best_entries": {},
		"score_endpoints": score_endpoints, "rank_count_cap": rank_count_cap}
	for score_endpoint in score_endpoints:
		var own_endpoint: String = score_endpoint.trim_suffix(".json") + "/%s.json" % _player_id
		_send_request(own_endpoint, HTTPClient.METHOD_GET, "", _on_own_score_request_completed.bind(standing_fetch))

#returns the leaderboard endpoint of each run day, or the all-time leaderboard endpoint without run days
func _get_score_endpoints(run_days: Array[int]) -> PackedStringArray:
	var score_endpoints: PackedStringArray = []
	if run_days.is_empty():
		score_endpoints.append("%s/scores.json" % _database_endpoint)
	for run_day in run_days:
		score_endpoints.append("%s/leaderboards/%d.json" % [_database_endpoint, run_day])
	return score_endpoints

#release endpoint only for release builds with debug_release off, otherwise the debug endpoint
func _resolve_database_endpoint() -> String:
	if not OS.is_debug_build() and FileAccess.file_exists(Globals.RUNTIME_CREDENTIALS):
		var production_config: ConfigFile = ConfigFile.new()
		if production_config.load(Globals.RUNTIME_CREDENTIALS) == OK:
			if bool(production_config.get_value("database", "debug_release", true)):
				return str(Configs.Leaderboard.debug_endpoint).strip_edges().trim_suffix("/")
			var release_endpoint: String = str(production_config.get_value("database", "database_endpoint", "")).strip_edges()
			if not release_endpoint.is_empty():
				return release_endpoint.trim_suffix("/")
		push_warning("LeaderboardManager._resolve_database_endpoint: invalid %s, using debug endpoint" % Globals.RUNTIME_CREDENTIALS)
	return str(Configs.Leaderboard.debug_endpoint).strip_edges().trim_suffix("/")

#loads the player id and username; the first launch, or a config from before player ids, makes a new id without a username
func _load_player_identity() -> void:
	var player_identity: ConfigFile = ConfigFile.new()
	if player_identity.load(PLAYER_IDENTITY) == OK:
		_player_id = str(player_identity.get_value("player", "player_id", ""))
		_username = str(player_identity.get_value("player", "username", ""))
	if _player_id.is_empty():
		_player_id = Crypto.new().generate_random_bytes(ID_BYTE_COUNT).hex_encode()
		_username = ""
		_save_player_identity()

#writes the player id and username to this device
func _save_player_identity() -> void:
	var player_identity: ConfigFile = ConfigFile.new()
	player_identity.set_value("player", "player_id", _player_id)
	player_identity.set_value("player", "username", _username)
	var save_error: Error = player_identity.save(PLAYER_IDENTITY)
	if save_error != OK:
		push_warning("LeaderboardManager._save_player_identity: cannot write %s (%s)" % [PLAYER_IDENTITY, error_string(save_error)])

#claims the new name and sets it on this player's score in one update, releasing the name the database held for this player
func _send_claim(claimed_username: String, server_username: String) -> void:
	var claimed_username_identifier: String = _to_username_identifier(claimed_username)
	var claim_changes: Dictionary = {
		"usernames/%s" % claimed_username_identifier: _player_id,
		"scores/%s/username" % _player_id: claimed_username,
	}
	if not server_username.is_empty() and _to_username_identifier(server_username) != claimed_username_identifier:
		claim_changes["usernames/%s" % _to_username_identifier(server_username)] = null
	var claim_endpoint: String = "%s/.json" % _database_endpoint
	_send_request(claim_endpoint, HTTPClient.METHOD_PATCH, JSON.stringify(claim_changes), _on_claim_request_completed.bind(claimed_username))

#stores the run score on the leaderboard of the given day; the database rules keep only a higher score of today
func _send_daily_score(run_points: int, run_day: int, submit_result: Globals.ScoreSubmit) -> void:
	var daily_score_endpoint: String = "%s/leaderboards/%d/%s.json" % [_database_endpoint, run_day, _player_id]
	var daily_score_body: String = JSON.stringify({"username": _username, "score": run_points})
	_send_request(daily_score_endpoint, HTTPClient.METHOD_PATCH, daily_score_body, _on_daily_request_completed.bind(submit_result))

#asks each leaderboard for the players scoring above the own standing, at most rank_count_cap per leaderboard
func _count_players_above(standing_fetch: Dictionary, own_standing: Dictionary) -> void:
	standing_fetch.pending_count = standing_fetch.score_endpoints.size()
	standing_fetch.own_standing = own_standing
	standing_fetch.players_above = {}
	standing_fetch.is_rank_capped = false

	var above_query: String = "orderBy=%s&startAt=%d&limitToFirst=%d" % [SCORE_ORDER.uri_encode(), own_standing.score + 1, standing_fetch.rank_count_cap]
	for score_endpoint in standing_fetch.score_endpoints:
		_send_request("%s?%s" % [score_endpoint, above_query], HTTPClient.METHOD_GET, "", _on_players_above_request_completed.bind(standing_fetch))

#returns the run day from the server Date header, in whole days since 1970-01-01 shifted by Configs.Leaderboard.day_utc_offset;
#the device clock is used when the header is missing (web builds never see it) or unreadable
func _day_from_headers(server_headers: PackedStringArray) -> int:
	var unix_seconds: int = int(Time.get_unix_time_from_system())
	var date_header: String = ""
	for http_header in server_headers:
		if http_header.to_lower().begins_with("date:"):
			date_header = http_header
			break

	if date_header.is_empty():
		push_warning("LeaderboardManager._day_from_headers: no Date header, using device clock")
	else:
		#e.g. "Date: Sun, 05 Oct 2026 10:00:00 GMT"
		var date_parts: PackedStringArray = date_header.substr("date:".length()).strip_edges().split(" ", false)
		var month_number: int = 0
		if date_parts.size() >= 5 and date_parts[1].is_valid_int() and date_parts[3].is_valid_int():
			month_number = MONTH_ABBREVIATIONS.find(date_parts[2]) + 1
		var header_seconds: int = 0
		if month_number > 0:
			var server_datetime: String = "%s-%02d-%02dT%s" % [date_parts[3], month_number, date_parts[1].to_int(), date_parts[4]]
			header_seconds = Time.get_unix_time_from_datetime_string(server_datetime)
		if header_seconds > 0:
			unix_seconds = header_seconds
		else:
			push_warning("LeaderboardManager._day_from_headers: unreadable header '%s', using device clock" % date_header)
	return floori(float(unix_seconds + int(Configs.Leaderboard.day_utc_offset) * HOUR_SECONDS) / DAY_SECONDS)

#lowercases the username so names differing only in letter case count as the same name
func _to_username_identifier(player_username: String) -> String:
	return player_username.to_lower()

#sends one request on its own HTTPRequest node, so requests never block each other;
#a GET of a finished day stored on this device, or answered within Configs.Leaderboard.answer_cache_seconds,
#is answered again from there on the next frame
func _send_request(request_endpoint: String, request_method: HTTPClient.Method, request_body: String, completed_callback: Callable) -> void:
	var server_request: HTTPRequest = HTTPRequest.new()
	server_request.timeout = Configs.Leaderboard.request_timeout
	add_child(server_request)
	var request_callback: Callable = completed_callback.bind(server_request)

	var is_cacheable: bool = request_method == HTTPClient.METHOD_GET
	if is_cacheable:
		_load_stored_answers()
	var stored_answer: Dictionary = _stored_answers.get(request_endpoint, {}) if is_cacheable else {}
	if not stored_answer.is_empty():
		var stored_body: PackedByteArray = str(stored_answer.server_body).to_utf8_buffer()
		request_callback.call_deferred(HTTPRequest.RESULT_SUCCESS, HTTPClient.RESPONSE_OK, PackedStringArray(), stored_body)
		return

	var cached_answer: Dictionary = _cached_answers.get(request_endpoint, {})
	if is_cacheable and not cached_answer.is_empty():
		if Time.get_ticks_msec() - cached_answer.msec < float(Configs.Leaderboard.answer_cache_seconds) * 1000.0:
			request_callback.call_deferred(cached_answer.fetch_result, cached_answer.response_code, cached_answer.server_headers, cached_answer.server_body)
			return
		_cached_answers.erase(request_endpoint)

	if is_cacheable:
		server_request.request_completed.connect(_on_cacheable_request_completed.bind(request_endpoint))
	server_request.request_completed.connect(request_callback)

	var request_error: Error = server_request.request(request_endpoint, PackedStringArray(), request_method, request_body)
	if request_error != OK:
		push_warning("LeaderboardManager._send_request: request failed to start (%s)" % error_string(request_error))
		request_callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

#returns the run day of a daily leaderboard endpoint that is finished, so its answer can no longer change, or NO_RUN_DAY
func _get_finished_run_day(request_endpoint: String) -> int:
	var run_day_match: RegExMatch = _run_day_endpoint_regex.search(request_endpoint)
	if run_day_match == null:
		return NO_RUN_DAY
	var run_day: int = run_day_match.get_string(1).to_int()
	return run_day if get_today_day() - run_day >= FINISHED_DAY_MARGIN else NO_RUN_DAY

#returns the oldest run day a tab still shows; stored answers of older days are dropped
func _get_oldest_shown_run_day() -> int:
	var shown_days: int = maxi(int(Configs.Leaderboard.daily_history_days), int(Configs.Leaderboard.weekly_history_weeks) * DAYS_PER_WEEK)
	return get_today_day() - shown_days

#loads the stored answers of finished days once, dropping the days no tab shows anymore
func _load_stored_answers() -> void:
	if _is_stored_answers_loaded:
		return
	_is_stored_answers_loaded = true
	if not FileAccess.file_exists(STORED_ANSWERS):
		return

	var stored_answers: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORED_ANSWERS))
	if not stored_answers is Dictionary:
		push_warning("LeaderboardManager._load_stored_answers: unreadable %s, starting empty" % STORED_ANSWERS)
		return
	var oldest_run_day: int = _get_oldest_shown_run_day()
	for request_endpoint in stored_answers:
		var stored_answer: Variant = stored_answers[request_endpoint]
		if stored_answer is Dictionary and stored_answer.get("server_body") is String and int(stored_answer.get("run_day", NO_RUN_DAY)) >= oldest_run_day:
			_stored_answers[request_endpoint] = stored_answer
	if _stored_answers.size() < stored_answers.size():
		_save_stored_answers()

#keeps the answer of a finished day on this device; a players-above answer keeps only the player ids,
#as counting the rank needs no names or scores
func _store_answer(request_endpoint: String, run_day: int, server_body: PackedByteArray) -> void:
	var answer_text: String = server_body.get_string_from_utf8()
	if request_endpoint.contains(PLAYERS_ABOVE_QUERY):
		var players_above: Variant = JSON.parse_string(answer_text)
		if players_above is Dictionary:
			var player_ids: Dictionary = {}
			for player_id in players_above:
				player_ids[player_id] = true
			answer_text = JSON.stringify(player_ids)
	_stored_answers[request_endpoint] = {"run_day": run_day, "server_body": answer_text}

	#answers arrive in bursts, one per day, so the file is written once after the burst
	if not _is_stored_answers_save_pending:
		_is_stored_answers_save_pending = true
		_save_stored_answers.call_deferred()

#writes the stored answers of finished days to this device
func _save_stored_answers() -> void:
	_is_stored_answers_save_pending = false
	var stored_answers_file: FileAccess = FileAccess.open(STORED_ANSWERS, FileAccess.WRITE)
	if stored_answers_file == null:
		push_warning("LeaderboardManager._save_stored_answers: cannot write %s (%s)" % [STORED_ANSWERS, error_string(FileAccess.get_open_error())])
		return
	stored_answers_file.store_string(JSON.stringify(_stored_answers))

#signal HTTPRequest.request_completed => keeps a successful GET answer for _send_request to reuse,
#and stores it on this device when it belongs to a finished day
func _on_cacheable_request_completed(fetch_result: int, response_code: int, server_headers: PackedStringArray, server_body: PackedByteArray, request_endpoint: String) -> void:
	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		return
	_cached_answers[request_endpoint] = {"msec": Time.get_ticks_msec(), "fetch_result": fetch_result, "response_code": response_code,
		"server_headers": server_headers, "server_body": server_body}

	var finished_run_day: int = _get_finished_run_day(request_endpoint)
	if finished_run_day != NO_RUN_DAY:
		_store_answer(request_endpoint, finished_run_day, server_body)

#signal HTTPRequest.request_completed => adopts the name the database holds for this player, then sends the claim
func _on_server_username_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, claimed_username: String) -> void:
	server_request.queue_free()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_server_username_request_completed: read failed (result %d, HTTP %d)" % [fetch_result, response_code])
		Signals.user_refused.emit(Globals.NameRefuse.Failed)
		return

	var server_username: Variant = JSON.parse_string(server_body.get_string_from_utf8())
	if not server_username is String:
		server_username = ""
	if not server_username.is_empty() and server_username != _username:
		_username = server_username
		_save_player_identity()
	_send_claim(claimed_username, server_username)

#signal HTTPRequest.request_completed => 200 means the name is this player's; 401 means another player has it
func _on_claim_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, _server_body: PackedByteArray, server_request: HTTPRequest, claimed_username: String) -> void:
	server_request.queue_free()

	if fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		_username = claimed_username
		_save_player_identity()
		_cached_answers.clear()
		Signals.user_saved.emit(claimed_username)
	elif fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		Signals.user_refused.emit(Globals.NameRefuse.Taken)
	else:
		push_warning("LeaderboardManager._on_claim_request_completed: claim failed (result %d, HTTP %d)" % [fetch_result, response_code])
		Signals.user_refused.emit(Globals.NameRefuse.Failed)

#signal HTTPRequest.request_completed => 200 means stored; 401 means the stored score is higher;
#unless it failed, the run is then sent to the leaderboard of the day the server reported
func _on_score_request_completed(fetch_result: int, response_code: int, server_headers: PackedStringArray, _server_body: PackedByteArray, server_request: HTTPRequest, run_points: int) -> void:
	server_request.queue_free()

	var submit_result: Globals.ScoreSubmit = Globals.ScoreSubmit.Failed
	if fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		submit_result = Globals.ScoreSubmit.Accepted
	elif fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		submit_result = Globals.ScoreSubmit.Stored
	else:
		push_warning("LeaderboardManager._on_score_request_completed: submit failed (result %d, HTTP %d)" % [fetch_result, response_code])
		Signals.score_submitted.emit(submit_result)
		return
	_send_daily_score(run_points, _day_from_headers(server_headers), submit_result)

#signal HTTPRequest.request_completed => 200 means stored; 401 means a higher score of today is stored or the day is not today;
#emits the all-time result, or Failed when the daily answer never came so the run stays pending for a resubmit;
#the cached answers are dropped first, so the boards fetched next hold the run
func _on_daily_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, _server_body: PackedByteArray, server_request: HTTPRequest, submit_result: Globals.ScoreSubmit) -> void:
	server_request.queue_free()
	_cached_answers.clear()

	var daily_submit_handled: bool = fetch_result == HTTPRequest.RESULT_SUCCESS and response_code in [HTTPClient.RESPONSE_OK, HTTPClient.RESPONSE_UNAUTHORIZED]
	if not daily_submit_handled:
		push_warning("LeaderboardManager._on_daily_request_completed: daily submit failed (result %d, HTTP %d)" % [fetch_result, response_code])
		submit_result = Globals.ScoreSubmit.Failed
	Signals.score_submitted.emit(submit_result)

#signal HTTPRequest.request_completed => keeps every listed day; no leaderboards at all answers null,
#a body that is neither null nor the day keys fails the fetch; emits the days holding scores newest first
func _on_run_days_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, fetch_key: String) -> void:
	server_request.queue_free()

	var run_days: Array[int] = []
	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_run_days_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		Signals.run_days_fetched.emit(fetch_key, false, run_days)
		return

	var run_day_keys_json: JSON = JSON.new()
	var parse_error: Error = run_day_keys_json.parse(server_body.get_string_from_utf8())
	var run_day_keys: Variant = run_day_keys_json.data
	if parse_error != OK or not (run_day_keys == null or run_day_keys is Dictionary):
		push_warning("LeaderboardManager._on_run_days_request_completed: unreadable day keys (%s)" % error_string(parse_error))
		Signals.run_days_fetched.emit(fetch_key, false, run_days)
		return

	if run_day_keys is Dictionary:
		for run_day_key in run_day_keys:
			if str(run_day_key).is_valid_int():
				run_days.append(str(run_day_key).to_int())
	run_days.sort()
	run_days.reverse()
	Signals.run_days_fetched.emit(fetch_key, true, run_days)

#signal HTTPRequest.request_completed => keeps this player's best score of the asked days; once every day answered,
#counts the players above it, or emits an empty standing when the player has no score there
func _on_own_score_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, standing_fetch: Dictionary) -> void:
	server_request.queue_free()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_own_score_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		standing_fetch.is_failed = true
	else:
		_merge_best_entries(standing_fetch.best_entries, {_player_id: JSON.parse_string(server_body.get_string_from_utf8())})

	standing_fetch.pending_count -= 1
	if standing_fetch.pending_count > 0:
		return
	if standing_fetch.is_failed:
		Signals.player_standing_fetched.emit(standing_fetch.fetch_key, false, {})
		return
	var own_entry: Dictionary = standing_fetch.best_entries.get(_player_id, {})
	if own_entry.is_empty():
		Signals.player_standing_fetched.emit(standing_fetch.fetch_key, true, {})
		return
	_count_players_above(standing_fetch, {"username": own_entry.username, "score": own_entry.score})

#signal HTTPRequest.request_completed => gathers the players above the own standing, each once over all leaderboards;
#once every leaderboard answered, emits the standing with rank = players above + 1, or the count itself when a cap was reached
func _on_players_above_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, standing_fetch: Dictionary) -> void:
	server_request.queue_free()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_players_above_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		standing_fetch.is_failed = true
	else:
		var players_above: Variant = JSON.parse_string(server_body.get_string_from_utf8())
		if players_above is Dictionary:
			standing_fetch.players_above.merge(players_above)
			if players_above.size() >= standing_fetch.rank_count_cap:
				standing_fetch.is_rank_capped = true

	standing_fetch.pending_count -= 1
	if standing_fetch.pending_count > 0:
		return
	if standing_fetch.is_failed:
		Signals.player_standing_fetched.emit(standing_fetch.fetch_key, false, {})
		return
	var own_standing: Dictionary = standing_fetch.own_standing
	var players_above_count: int = standing_fetch.players_above.size()
	own_standing.is_rank_capped = standing_fetch.is_rank_capped
	own_standing.rank = players_above_count if own_standing.is_rank_capped else players_above_count + 1
	Signals.player_standing_fetched.emit(standing_fetch.fetch_key, true, own_standing)

#keeps each fetched player's best score, so a player on several daily leaderboards is counted once
func _merge_best_entries(best_entries: Dictionary, fetched_scores: Variant) -> void:
	if not fetched_scores is Dictionary:
		return
	for player_id in fetched_scores:
		var score_entry: Variant = fetched_scores[player_id]
		if not score_entry is Dictionary or not score_entry.get("username") is String:
			continue
		if not (score_entry.get("score") is float or score_entry.get("score") is int):
			continue
		var player_score: int = int(score_entry.score)
		if best_entries.has(player_id) and best_entries[player_id].score >= player_score:
			continue
		best_entries[player_id] = {"player_id": str(player_id), "username": score_entry.username, "score": player_score}

#signal HTTPRequest.request_completed => once every requested leaderboard answered, emits the best scores sorted best first;
#a single failed leaderboard fails the whole fetch, so a partial board is never shown
func _on_rankings_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, rankings_fetch: Dictionary) -> void:
	server_request.queue_free()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_rankings_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		rankings_fetch.is_failed = true
	else:
		_merge_best_entries(rankings_fetch.best_entries, JSON.parse_string(server_body.get_string_from_utf8()))

	rankings_fetch.pending_count -= 1
	if rankings_fetch.pending_count > 0:
		return

	var rank_entries: Array[Dictionary] = []
	if rankings_fetch.is_failed:
		Signals.ranks_fetched.emit(rankings_fetch.fetch_key, false, rank_entries)
		return

	rank_entries.assign(rankings_fetch.best_entries.values())
	rank_entries.sort_custom(func(first_entry: Dictionary, second_entry: Dictionary) -> bool: return first_entry.score > second_entry.score)
	rank_entries.resize(mini(rank_entries.size(), Configs.Leaderboard.top_count))
	Signals.ranks_fetched.emit(rankings_fetch.fetch_key, true, rank_entries)
