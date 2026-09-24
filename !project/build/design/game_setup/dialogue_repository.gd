extends Node

signal content_activated(content_version: int)
signal remote_update_started
signal remote_update_finished(succeeded: bool, applied: bool, content_version: int)

const TEST_FILE_URL: String = "https://zeljko-vulovic.github.io/glasalica/style.css"
const REMOTE_ARCHIVE_URL_SETTING: String = "dialogues/remote_archive_url"

const EMBEDDED_DIRECTORY: String = "res://!project/build/design/dialogues"
const EMBEDDED_ARCHIVE_PATH: String = EMBEDDED_DIRECTORY + "/dialogues.zip"
const EMBEDDED_MANIFEST_PATH: String = EMBEDDED_DIRECTORY + "/manifest.json"

const CACHE_DIRECTORY: String = "user://dialogues"
const CACHED_ARCHIVE_PATH: String = CACHE_DIRECTORY + "/dialogues.zip"
const PENDING_ARCHIVE_PATH: String = CACHE_DIRECTORY + "/dialogues.download"
const BACKUP_ARCHIVE_PATH: String = CACHE_DIRECTORY + "/dialogues.backup"

const SUPPORTED_SCHEMA_VERSION: int = 1
const SUPPORTED_FILE_TEMPLATE: String = "voter_{topic}_dialog_{personality}_{index}.json"
const SUPPORTED_INDEX_WIDTH: int = 2

var _active_manifest: Dictionary = {}
var _active_directory: String = ""
var _active_content_version: int = 0
var _remote_update_in_progress: bool = false
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	DirAccess.make_dir_recursive_absolute(CACHE_DIRECTORY)
	_initialize_active_content()
	_download_test_file()

	var remote_archive_url: String = str(
		ProjectSettings.get_setting(REMOTE_ARCHIVE_URL_SETTING, "")
	).strip_edges()
	if not remote_archive_url.is_empty():
		download_remote_archive(remote_archive_url)


func create_voter_descriptor() -> VoterDescriptor:
	var personalities: Array = _active_manifest.get("personalities", [])
	if personalities.is_empty() or _active_directory.is_empty():
		return VoterDescriptor.new("", {})

	var personality: String = str(personalities[_random.randi_range(0, personalities.size() - 1)])
	var selected_dialogues: Dictionary = {}
	var dialogues: Dictionary = _active_manifest.get("dialogues", {})

	for topic_variant in dialogues:
		var topic: String = str(topic_variant)
		var topic_dialogues: Dictionary = dialogues[topic_variant]
		var count: int = int(topic_dialogues.get(personality, 0))
		if count <= 0:
			continue

		var index: int = _random.randi_range(1, count)
		var file_name: String = _get_dialogue_file_name(topic, personality, index, _active_manifest)
		selected_dialogues[topic] = _active_directory.path_join(file_name)

	return VoterDescriptor.new(personality, selected_dialogues, _active_content_version)


func get_active_content_version() -> int:
	return _active_content_version


func is_remote_update_in_progress() -> bool:
	return _remote_update_in_progress


# A future waiting popup can await this method before allowing gameplay to continue.
func wait_for_remote_update() -> void:
	if _remote_update_in_progress:
		await remote_update_finished


func download_remote_archive(url: String) -> Error:
	if _remote_update_in_progress:
		return ERR_BUSY
	if url.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER

	_remove_file_if_exists(PENDING_ARCHIVE_PATH)

	var request := HTTPRequest.new()
	request.download_file = PENDING_ARCHIVE_PATH
	request.timeout = 0.0
	add_child(request)
	request.request_completed.connect(_on_remote_archive_request_completed.bind(request))

	var error: Error = request.request(url)
	if error != OK:
		request.queue_free()
		return error

	_remote_update_in_progress = true
	remote_update_started.emit()
	return OK


func _initialize_active_content() -> void:
	var best_candidate: Dictionary = {}

	for archive_path in [EMBEDDED_ARCHIVE_PATH, CACHED_ARCHIVE_PATH]:
		var candidate: Dictionary = _load_archive_candidate(archive_path)
		if candidate.is_empty():
			continue
		if best_candidate.is_empty() or candidate["version"] >= best_candidate["version"]:
			best_candidate = candidate

	if not best_candidate.is_empty() and _activate_archive(
		best_candidate["path"], best_candidate["manifest"]
	):
		_cleanup_inactive_build_directories()
		return

	if _activate_loose_embedded_dialogues():
		_cleanup_inactive_build_directories()
		return

	push_error("[DIALOGUES] No valid dialogue package is available.")


func _download_test_file() -> void:
	var request := HTTPRequest.new()
	request.timeout = 10.0
	add_child(request)
	request.request_completed.connect(_on_test_file_request_completed.bind(request))

	var error: Error = request.request(TEST_FILE_URL)
	if error != OK:
		push_warning("[DIALOGUES] Could not start test download: %s" % error_string(error))
		request.queue_free()


func _on_test_file_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest
) -> void:
	request.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		push_warning(
			"[DIALOGUES] Test download failed (result %d, HTTP %d). Continuing with local dialogues."
			% [result, response_code]
		)
		return

	print("[DIALOGUES] Downloaded %s:\n%s" % [TEST_FILE_URL, body.get_string_from_utf8()])


func _on_remote_archive_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	_body: PackedByteArray,
	request: HTTPRequest
) -> void:
	request.queue_free()
	_remote_update_in_progress = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_remove_file_if_exists(PENDING_ARCHIVE_PATH)
		push_warning(
			"[DIALOGUES] Archive download failed (result %d, HTTP %d). Keeping current dialogues."
			% [result, response_code]
		)
		remote_update_finished.emit(false, false, _active_content_version)
		return

	var candidate: Dictionary = _load_archive_candidate(PENDING_ARCHIVE_PATH)
	if candidate.is_empty():
		_remove_file_if_exists(PENDING_ARCHIVE_PATH)
		push_warning("[DIALOGUES] Downloaded archive failed validation. Keeping current dialogues.")
		remote_update_finished.emit(false, false, _active_content_version)
		return

	var downloaded_version: int = candidate["version"]
	var applied: bool = false
	if downloaded_version > _active_content_version:
		applied = _activate_archive(PENDING_ARCHIVE_PATH, candidate["manifest"])

	var cached_candidate: Dictionary = _load_archive_candidate(CACHED_ARCHIVE_PATH)
	var cached_version: int = int(cached_candidate.get("version", 0))
	if downloaded_version > cached_version:
		if not _replace_cached_archive():
			push_warning("[DIALOGUES] The update is active, but its archive could not be cached.")
	else:
		_remove_file_if_exists(PENDING_ARCHIVE_PATH)

	remote_update_finished.emit(true, applied, downloaded_version)


func _load_archive_candidate(archive_path: String) -> Dictionary:
	if not FileAccess.file_exists(archive_path):
		return {}

	var reader := ZIPReader.new()
	var open_error: Error = reader.open(archive_path)
	if open_error != OK:
		return {}
	if not reader.file_exists("manifest.json"):
		reader.close()
		return {}

	var manifest_data = JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8())
	if not manifest_data is Dictionary or not _validate_manifest(manifest_data):
		reader.close()
		return {}

	for file_name in _get_declared_dialogue_files(manifest_data):
		if not reader.file_exists(file_name):
			reader.close()
			return {}
		var dialogue_data = JSON.parse_string(reader.read_file(file_name).get_string_from_utf8())
		if not dialogue_data is Dictionary:
			reader.close()
			return {}

	reader.close()
	return {
		"path": archive_path,
		"manifest": manifest_data,
		"version": int(manifest_data["content_version"]),
	}


func _activate_archive(archive_path: String, manifest: Dictionary) -> bool:
	var version: int = int(manifest["content_version"])
	var destination: String = CACHE_DIRECTORY.path_join("build_%d" % version)

	if not _is_extracted_build_valid(destination, manifest):
		_delete_directory_recursive(destination)
		if not _extract_archive(archive_path, destination, manifest):
			return false

	_active_manifest = manifest.duplicate(true)
	_active_directory = destination
	_active_content_version = version
	print("[DIALOGUES] Activated dialogue content version %d from %s" % [version, archive_path])
	content_activated.emit(version)
	return true


func _activate_loose_embedded_dialogues() -> bool:
	if not FileAccess.file_exists(EMBEDDED_MANIFEST_PATH):
		return false

	var manifest_data = JSON.parse_string(FileAccess.get_file_as_string(EMBEDDED_MANIFEST_PATH))
	if not manifest_data is Dictionary or not _validate_manifest(manifest_data):
		return false
	for file_name in _get_declared_dialogue_files(manifest_data):
		if not FileAccess.file_exists(EMBEDDED_DIRECTORY.path_join(file_name)):
			return false

	_active_manifest = manifest_data.duplicate(true)
	_active_directory = EMBEDDED_DIRECTORY
	_active_content_version = int(manifest_data["content_version"])
	print("[DIALOGUES] Activated loose embedded dialogue content version %d" % _active_content_version)
	content_activated.emit(_active_content_version)
	return true


func _extract_archive(archive_path: String, destination: String, manifest: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		return false

	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK:
		_delete_directory_recursive(destination)
		return false

	var files: Array[String] = ["manifest.json"]
	files.append_array(_get_declared_dialogue_files(manifest))
	for file_name in files:
		var output := FileAccess.open(destination.path_join(file_name), FileAccess.WRITE)
		if output == null:
			reader.close()
			_delete_directory_recursive(destination)
			return false
		output.store_buffer(reader.read_file(file_name))
		output.close()

	reader.close()
	return _is_extracted_build_valid(destination, manifest)


func _is_extracted_build_valid(directory: String, manifest: Dictionary) -> bool:
	var manifest_path: String = directory.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return false

	var extracted_manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not extracted_manifest is Dictionary:
		return false
	if int(extracted_manifest.get("content_version", 0)) != int(manifest["content_version"]):
		return false

	for file_name in _get_declared_dialogue_files(manifest):
		if not FileAccess.file_exists(directory.path_join(file_name)):
			return false
	return true


func _validate_manifest(manifest: Dictionary) -> bool:
	if not _is_integer_number(manifest.get("schema_version"), SUPPORTED_SCHEMA_VERSION):
		return false
	if not _is_positive_integer(manifest.get("content_version")):
		return false

	var filename_config = manifest.get("filename", {})
	if not filename_config is Dictionary:
		return false
	var template: String = str(filename_config.get("template", ""))
	if template != SUPPORTED_FILE_TEMPLATE:
		return false
	if not _is_integer_number(filename_config.get("index_width"), SUPPORTED_INDEX_WIDTH):
		return false

	var personalities = manifest.get("personalities", [])
	var dialogues = manifest.get("dialogues", {})
	if not personalities is Array or personalities.is_empty() or not dialogues is Dictionary \
		or dialogues.is_empty():
		return false

	for topic_variant in dialogues:
		var topic: String = str(topic_variant)
		if not _is_safe_name_part(topic) or not dialogues[topic_variant] is Dictionary:
			return false
		for personality_variant in dialogues[topic_variant]:
			var personality: String = str(personality_variant)
			if not _is_safe_name_part(personality) or not personalities.has(personality):
				return false
			if not _is_non_negative_integer(dialogues[topic_variant][personality_variant]):
				return false

	var unique_personalities: Dictionary = {}
	for personality_variant in personalities:
		var personality: String = str(personality_variant)
		if not _is_safe_name_part(personality) or unique_personalities.has(personality):
			return false
		unique_personalities[personality] = true
	return true


func _get_declared_dialogue_files(manifest: Dictionary) -> Array[String]:
	var files: Array[String] = []
	var dialogues: Dictionary = manifest.get("dialogues", {})
	for topic_variant in dialogues:
		var topic: String = str(topic_variant)
		var topic_dialogues: Dictionary = dialogues[topic_variant]
		for personality_variant in topic_dialogues:
			var personality: String = str(personality_variant)
			var count: int = int(topic_dialogues[personality_variant])
			for index in range(1, count + 1):
				files.append(_get_dialogue_file_name(topic, personality, index, manifest))
	return files


func _get_dialogue_file_name(
	topic: String,
	personality: String,
	index: int,
	manifest: Dictionary
) -> String:
	var filename_config: Dictionary = manifest["filename"]
	var index_text: String = str(index).pad_zeros(int(filename_config["index_width"]))
	return str(filename_config["template"]) \
		.replace("{topic}", topic) \
		.replace("{personality}", personality) \
		.replace("{index}", index_text)


func _replace_cached_archive() -> bool:
	_remove_file_if_exists(BACKUP_ARCHIVE_PATH)
	if FileAccess.file_exists(CACHED_ARCHIVE_PATH):
		if DirAccess.rename_absolute(CACHED_ARCHIVE_PATH, BACKUP_ARCHIVE_PATH) != OK:
			return false

	if DirAccess.rename_absolute(PENDING_ARCHIVE_PATH, CACHED_ARCHIVE_PATH) != OK:
		if FileAccess.file_exists(BACKUP_ARCHIVE_PATH):
			DirAccess.rename_absolute(BACKUP_ARCHIVE_PATH, CACHED_ARCHIVE_PATH)
		return false

	_remove_file_if_exists(BACKUP_ARCHIVE_PATH)
	return true


func _cleanup_inactive_build_directories() -> void:
	for directory_name in DirAccess.get_directories_at(CACHE_DIRECTORY):
		if not directory_name.begins_with("build_"):
			continue
		var directory_path: String = CACHE_DIRECTORY.path_join(directory_name)
		if directory_path != _active_directory:
			_delete_directory_recursive(directory_path)


func _delete_directory_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return

	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_delete_directory_recursive(entry_path)
			else:
				DirAccess.remove_absolute(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _is_safe_name_part(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		if not "abcdefghijklmnopqrstuvwxyz0123456789_".contains(character.to_lower()):
			return false
	return true


func _is_positive_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) == float(int(value)) and int(value) > 0


func _is_integer_number(value: Variant, expected: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) == float(int(value)) and int(value) == expected


func _is_non_negative_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) == float(int(value)) and int(value) >= 0
