##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Online leaderboard over the Firebase Realtime Database REST api;
#                  scores are stored under a random player id made once per install,
#                  usernames are unique through the usernames list (see database.rules.json);
#                  release builds use the release endpoint from the gitignored config
#                  once its debug_release is false, everything else uses the committed debug endpoint
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
extends Node

const ID_BYTE_COUNT: int = 16
const PLAYER_IDENTITY: String = "user://player_identity.cfg"

#letters, digits, space, _ and -;
#must match the pattern in database.rules.json
const NAME_PATTERN: String = "^[A-Za-z0-9 _-]+$"

const NO_RUN_POINTS_PENDING: int = -1


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

#stores the score under this player's id; the database rules keep only a higher score
func submit_score(player_score: int) -> void:
	if not is_enabled() or _username.is_empty():
		Signals.score_submitted.emit(Globals.ScoreSubmit.Failed)
		return

	var score_endpoint: String = "%s/scores/%s.json" % [_database_endpoint, _player_id]
	var score_body: String = JSON.stringify({"score": player_score})
	_send_request(score_endpoint, HTTPClient.METHOD_PATCH, score_body, _on_score_request_completed)

#fetches the best scores; the result arrives through Signals.ranks_fetched
func fetch_rankings() -> void:
	if not is_enabled():
		Signals.ranks_fetched.emit(false, [] as Array[Dictionary])
		return

	var top_endpoint: String = "%s/scores.json?orderBy=%s&limitToLast=%d" % [
		_database_endpoint, "\"score\"".uri_encode(), Configs.Leaderboard.top_count
	]
	_send_request(top_endpoint, HTTPClient.METHOD_GET, "", _on_top_request_completed)

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

#signal HTTPRequest.request_completed => 200 means stored; 401 means the stored score is higher
func _on_score_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, _server_body: PackedByteArray, server_request: HTTPRequest) -> void:
	server_request.queue_free()

	var submit_result: Globals.ScoreSubmit = Globals.ScoreSubmit.Failed
	if fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_OK:
		submit_result = Globals.ScoreSubmit.Accepted
	elif fetch_result == HTTPRequest.RESULT_SUCCESS and response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		submit_result = Globals.ScoreSubmit.Stored
	else:
		push_warning("LeaderboardManager._on_score_request_completed: submit failed (result %d, HTTP %d)" % [fetch_result, response_code])
	Signals.score_submitted.emit(submit_result)

#signal HTTPRequest.request_completed => emits the fetched scores sorted best first
func _on_top_request_completed(fetch_result: int, response_code: int, _server_headers: PackedStringArray, server_body: PackedByteArray, server_request: HTTPRequest) -> void:
	server_request.queue_free()

	var top_entries: Array[Dictionary] = []
	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		push_warning("LeaderboardManager._on_top_request_completed: fetch failed (result %d, HTTP %d)" % [fetch_result, response_code])
		Signals.ranks_fetched.emit(false, top_entries)
		return

	var fetched_scores: Variant = JSON.parse_string(server_body.get_string_from_utf8())
	if fetched_scores is Dictionary:
		for player_id in fetched_scores:
			var score_entry: Variant = fetched_scores[player_id]
			if score_entry is Dictionary and score_entry.get("username") is String and (score_entry.get("score") is float or score_entry.get("score") is int):
				top_entries.append({"player_id": str(player_id), "username": score_entry.username, "score": int(score_entry.score)})
	top_entries.sort_custom(func(first_entry: Dictionary, second_entry: Dictionary) -> bool: return first_entry.score > second_entry.score)
	Signals.ranks_fetched.emit(true, top_entries)
