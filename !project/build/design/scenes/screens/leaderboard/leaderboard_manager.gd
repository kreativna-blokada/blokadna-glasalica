##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Online leaderboard manager over Firebase Realtime Database
#maintainer      : Zeljko
#version         : 1.2
#===============================================================================
extends Node

const ID_BYTE_COUNT: int = 16
const PLAYER_IDENTITY: String = "user://player_identity.cfg"

#letters, digits, space, _ and -;
#must match the pattern in database.rules.json
const NAME_PATTERN: String = "^[A-Za-z0-9 _-]+$"

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

#fetches the best scores of the given run days, each player once with their best score of those days;
#without run days fetches the best all-time scores; the result arrives through Signals.ranks_fetched
func fetch_rankings(run_days: Array[int] = []) -> void:
	if not is_enabled():
		Signals.ranks_fetched.emit(false, [] as Array[Dictionary])
		return

	var top_query: String = "orderBy=%s&limitToLast=%d" % ["\"score\"".uri_encode(), Configs.Leaderboard.top_count]
	var rankings_fetch: Dictionary = {"pending_count": maxi(run_days.size(), 1), "is_failed": false, "best_entries": {}}
	if run_days.is_empty():
		var total_endpoint: String = "%s/scores.json?%s" % [_database_endpoint, top_query]
		_send_request(total_endpoint, HTTPClient.METHOD_GET, "", _on_top_request_completed.bind(rankings_fetch))
		return

	for run_day in run_days:
		var daily_endpoint: String = "%s/leaderboards/%d.json?%s" % [_database_endpoint, run_day, top_query]
		_send_request(daily_endpoint, HTTPClient.METHOD_GET, "", _on_top_request_completed.bind(rankings_fetch))

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

#sends one request on its own HTTPRequest node, so requests never block each other
func _send_request(request_endpoint: String, request_method: HTTPClient.Method, request_body: String, completed_callback: Callable) -> void:
	var server_request: HTTPRequest = HTTPRequest.new()
	server_request.timeout = Configs.Leaderboard.request_timeout
	add_child(server_request)
	var request_callback: Callable = completed_callback.bind(server_request)
	server_request.request_completed.connect(request_callback)

	var request_error: Error = server_request.request(request_endpoint, PackedStringArray(), request_method, request_body)
	if request_error != OK:
		push_warning("LeaderboardManager._send_request: request failed to start (%s)" % error_string(request_error))
		request_callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

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
#emits the all-time result, or Failed when the daily answer never came so the run stays pending for a resubmit
func _on_daily_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, _server_body: PackedByteArray, server_request: HTTPRequest, submit_result: Globals.ScoreSubmit) -> void:
	server_request.queue_free()

	var daily_submit_handled: bool = fetch_result == HTTPRequest.RESULT_SUCCESS and response_code in [HTTPClient.RESPONSE_OK, HTTPClient.RESPONSE_UNAUTHORIZED]
	if not daily_submit_handled:
		push_warning("LeaderboardManager._on_daily_request_completed: daily submit failed (result %d, HTTP %d)" % [fetch_result, response_code])
		submit_result = Globals.ScoreSubmit.Failed
	Signals.score_submitted.emit(submit_result)

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
func _on_top_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest, rankings_fetch: Dictionary) -> void:
	server_request.queue_free()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_top_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		rankings_fetch.is_failed = true
	else:
		_merge_best_entries(rankings_fetch.best_entries, JSON.parse_string(server_body.get_string_from_utf8()))

	rankings_fetch.pending_count -= 1
	if rankings_fetch.pending_count > 0:
		return

	var top_entries: Array[Dictionary] = []
	if rankings_fetch.is_failed:
		Signals.ranks_fetched.emit(false, top_entries)
		return

	top_entries.assign(rankings_fetch.best_entries.values())
	top_entries.sort_custom(func(first_entry: Dictionary, second_entry: Dictionary) -> bool: return first_entry.score > second_entry.score)
	top_entries.resize(mini(top_entries.size(), Configs.Leaderboard.top_count))
	Signals.ranks_fetched.emit(true, top_entries)
