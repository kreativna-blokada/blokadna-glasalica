##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Dialogue content provider; uses the latest of built-in/cached content
#                  and refreshes the cache from GitHub on every start (ETag-conditional)
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
extends Node

#scrambled content shipped inside the build as the offline fallback; same file as the hosted one
const HOSTED_DIALOGUES: String = "https://raw.githubusercontent.com/kreativna-blokada/blokadna-glasalica/main/!project/dialogues/dialogues_content.bin"
#previous hosting location of the same content; fallback only while the current one is unreachable
const LEGACY_HOSTED_DIALOGUES: String = "https://raw.githubusercontent.com/zeljko-vulovic/glasalica/main/dialogues.bin"
const DOWNLOAD_TIMEOUT: float = 10.0

const BUILTIN_DIALOGUES: String = "res://!project/dialogues/dialogues_content.bin"
const DIALOGUES_ETAG: String = "user://dialogues_content.etag"
const DIALOGUES_CACHE: String = "user://dialogues_content.bin"

#dialogue ids are the source file names: voter_{topic}_dialog_{personality}_{variant}
const DIALOGUE_ID_FORMAT: String = "^voter_(?<topic>.+?)_dialog_(?<personality>.+)_(?<variant>\\d+)$"
#dialogue node field; from this app version on, and on web, the node is skipped, e.g. an update notice
const SKIP_FROM_VERSION: String = "skip_from_version"


#private vars
var _fetch_dialogues: HTTPRequest = null
var _fetched_dialogues_url: String = ""
var _active_dialogues_version: int = -1
var _active_dialogues: Dictionary = {}
var _dialogue_variants: Dictionary = {}

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_load_offline_dialogues()
	_fetch_online_dialogues()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#checks whether a dialogue with the given id exists in the loaded content
func has_dialogue(id: String) -> bool:
	return _active_dialogues.has(id)

#returns the dialogue tree data for the given id without the nodes skipped for this app version (a skipped root stays when nothing visible follows), or an empty dictionary if missing
func get_dialogue(id: String) -> Dictionary:
	var dialogue_nodes: Dictionary = _active_dialogues.get(id, {}).duplicate(true)
	for dialogue_node: Dictionary in dialogue_nodes.values():
		if dialogue_node.has("next"):
			dialogue_node.next = _skip_hidden_nodes(dialogue_nodes, dialogue_node.next)
		for choice: Dictionary in dialogue_node.get("choices", []):
			if choice.has("next"):
				choice.next = _skip_hidden_nodes(dialogue_nodes, choice.next)

	var visible_root_id: String = _skip_hidden_nodes(dialogue_nodes, "root")
	if visible_root_id != "root" and visible_root_id != "":
		dialogue_nodes.root = dialogue_nodes[visible_root_id]
	return dialogue_nodes

#picks a random personality and a random dialogue variant per topic for a new voter
func create_voter_descriptor() -> VoterDescriptor:
	if _dialogue_variants.is_empty():
		return VoterDescriptor.new("", {})

	var voter_personality: String = _dialogue_variants.keys().pick_random()
	var topic_variants: Dictionary = _dialogue_variants[voter_personality]
	var voter_dialogues: Dictionary = {}
	for topic in topic_variants:
		voter_dialogues[topic] = topic_variants[topic].pick_random()
	return VoterDescriptor.new(voter_personality, voter_dialogues)

#follows the links past nodes skipped for this app version; returns the first visible node id, or "" at the dialogue end
func _skip_hidden_nodes(dialogue_nodes: Dictionary, next_node_id: String) -> String:
	#bounded by the node count so a loop of skipped nodes cannot hang the game
	for _skipped_node_count in dialogue_nodes.size():
		if not dialogue_nodes.has(next_node_id) or not _is_node_skipped(dialogue_nodes[next_node_id]):
			break
		next_node_id = _get_skipped_node_next(dialogue_nodes[next_node_id])
	return next_node_id

#checks whether the node has skip_from_version and the game runs on web or on that app version or newer
func _is_node_skipped(dialogue_node: Dictionary) -> bool:
	if not dialogue_node.has(SKIP_FROM_VERSION):
		return false
	return OS.has_feature("web") or _is_app_version_at_least(str(dialogue_node[SKIP_FROM_VERSION]))

#returns where a skipped node leads: its next, or the next its choices share
func _get_skipped_node_next(dialogue_node: Dictionary) -> String:
	if dialogue_node.has("choices"):
		return dialogue_node.choices[0].get("next", "")
	return dialogue_node.get("next", "")

#checks whether this app version (application/config/version) is at least the given one, e.g. "1.3.0"
func _is_app_version_at_least(required_version: String) -> bool:
	var app_version_parts: PackedStringArray = str(ProjectSettings.get_setting("application/config/version")).split(".")
	var required_version_parts: PackedStringArray = required_version.split(".")

	for part_index in maxi(app_version_parts.size(), required_version_parts.size()):
		var app_version_part: int = int(app_version_parts[part_index]) if part_index < app_version_parts.size() else 0
		var required_version_part: int = int(required_version_parts[part_index]) if part_index < required_version_parts.size() else 0
		if app_version_part != required_version_part:
			return app_version_part > required_version_part
	return true

#groups the active dialogue ids as {personality: {topic: [ids]}}; ids not matching the pattern are skipped
func _index_dialogue_variants() -> void:
	_dialogue_variants.clear()

	var dialogue_id_format: RegEx = RegEx.create_from_string(DIALOGUE_ID_FORMAT)
	for dialogue_id in _active_dialogues:
		var match_id: RegExMatch = dialogue_id_format.search(dialogue_id)
		if match_id == null:
			continue
		var personality_topics: Dictionary = _dialogue_variants.get_or_add(match_id.get_string("personality"), {})
		var topic_dialogues: Array = personality_topics.get_or_add(match_id.get_string("topic"), [])
		topic_dialogues.append(dialogue_id)

#loads built-in content, then the cached downloaded content if it is not older
func _load_offline_dialogues() -> void:
	if not FileAccess.file_exists(BUILTIN_DIALOGUES):
		push_error("DialoguesManager._load_offline_dialogues: missing built-in content at %s" % BUILTIN_DIALOGUES)
	else:
		_set_active_dialogues(_parse_scrambled_dialogues(FileAccess.get_file_as_bytes(BUILTIN_DIALOGUES)))

	if FileAccess.file_exists(DIALOGUES_CACHE):
		_set_active_dialogues(_parse_scrambled_dialogues(FileAccess.get_file_as_bytes(DIALOGUES_CACHE)))

#starts downloading the hosted content from the given location; sends the cached etag only to the current one
func _fetch_online_dialogues(hosted_dialogues_url: String = HOSTED_DIALOGUES) -> void:
	_fetched_dialogues_url = hosted_dialogues_url
	_fetch_dialogues = HTTPRequest.new()
	_fetch_dialogues.timeout = DOWNLOAD_TIMEOUT
	add_child(_fetch_dialogues)
	_fetch_dialogues.request_completed.connect(_on_request_completed)

	var request_headers: PackedStringArray = PackedStringArray()
	#on web the browser cache revalidates by itself; a custom header would force a CORS preflight
	if hosted_dialogues_url == HOSTED_DIALOGUES and not OS.has_feature("web") and FileAccess.file_exists(DIALOGUES_ETAG) and FileAccess.file_exists(DIALOGUES_CACHE):
		request_headers.append("If-None-Match: " + FileAccess.get_file_as_string(DIALOGUES_ETAG))

	var request_error: Error = _fetch_dialogues.request(hosted_dialogues_url, request_headers)
	if request_error != OK:
		push_warning("DialoguesManager._fetch_online_dialogues: request failed to start (%s)" % error_string(request_error))
		_dispose_fetch_request()

#signal HTTPRequest.request_completed => uses and caches valid newer content; 304 or failure keeps the current one
func _on_request_completed(fetch_result: int, response_code: int, server_headers: PackedStringArray, server_body: PackedByteArray) -> void:
	_dispose_fetch_request()

	if fetch_result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		#current location unreachable or not published yet => try the previous one once; 304 means content is current
		if response_code != HTTPClient.RESPONSE_NOT_MODIFIED and _fetched_dialogues_url == HOSTED_DIALOGUES:
			_fetch_online_dialogues(LEGACY_HOSTED_DIALOGUES)
		return

	var dialogues_content: Dictionary = _parse_scrambled_dialogues(server_body)
	if dialogues_content.is_empty():
		push_warning("DialoguesManager._on_request_completed: downloaded content is invalid, ignored")
		return

	if not _set_active_dialogues(dialogues_content):
		return
	_save_dialogues(server_body)
	if _fetched_dialogues_url != HOSTED_DIALOGUES:
		return
	for server_header in server_headers:
		if server_header.to_lower().begins_with("etag:"):
			_save_etag(server_header.substr(5).strip_edges())

#removes the finished download request node
func _dispose_fetch_request() -> void:
	_fetch_dialogues.queue_free()
	_fetch_dialogues = null

#takes the content only if it is not older than the one in use; returns whether it was taken
func _set_active_dialogues(parsed_dialogues: Dictionary) -> bool:
	if parsed_dialogues.is_empty() or parsed_dialogues.version < _active_dialogues_version:
		return false
	_active_dialogues_version = parsed_dialogues.version
	_active_dialogues = parsed_dialogues.dialogues
	_index_dialogue_variants()
	return true

#returns {version, dialogues} or an empty dictionary if the data is not valid content
func _parse_scrambled_dialogues(downloaded_dialogues: PackedByteArray) -> Dictionary:
	var readable_dialogues: PackedByteArray = DialogueScrambler.unscramble_dialogue_content(downloaded_dialogues)
	if readable_dialogues.is_empty():
		return {}

	var json_parser: JSON = JSON.new()
	if json_parser.parse(readable_dialogues.get_string_from_utf8()) != OK or not json_parser.data is Dictionary:
		return {}
	var parsed_dialogues: Dictionary = json_parser.data
	if not parsed_dialogues.get("dialogues") is Dictionary:
		return {}
	for parsed_dialogue in parsed_dialogues.dialogues.values():
		if not parsed_dialogue is Dictionary or not DialogTree.find_data_error(parsed_dialogue).is_empty():
			return {}

	return {"version": int(parsed_dialogues.get("version", 0)), "dialogues": parsed_dialogues.dialogues}

#writes the downloaded scrambled content to the user cache
func _save_dialogues(scrambled_dialogues: PackedByteArray) -> void:
	var dialogues_cache_file: FileAccess = FileAccess.open(DIALOGUES_CACHE, FileAccess.WRITE)
	if dialogues_cache_file == null:
		push_warning("DialoguesManager._save_dialogues: cannot write %s (%s)" % [DIALOGUES_CACHE, error_string(FileAccess.get_open_error())])
		return
	dialogues_cache_file.store_buffer(scrambled_dialogues)

#writes the etag of the cached content, used to skip unchanged downloads
func _save_etag(etag_value: String) -> void:
	var etag_cache_file: FileAccess = FileAccess.open(DIALOGUES_ETAG, FileAccess.WRITE)
	if etag_cache_file == null:
		push_warning("DialoguesManager._save_etag: cannot write %s (%s)" % [DIALOGUES_ETAG, error_string(FileAccess.get_open_error())])
		return
	etag_cache_file.store_string(etag_value)
