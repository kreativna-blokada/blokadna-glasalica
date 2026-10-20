@tool
extends RefCounted

const DIALOGUE_DIRECTORY: String = "res://!project/dialogues"
const CONTENT_DIRECTORY: String = DIALOGUE_DIRECTORY + "/content"
const MANIFEST_PATH: String = DIALOGUE_DIRECTORY + "/manifest.json"
const ARCHIVE_PATH: String = DIALOGUE_DIRECTORY + "/dialogues.zip"
const TEMP_MANIFEST_PATH: String = DIALOGUE_DIRECTORY + "/manifest.json.tmp"
const TEMP_ARCHIVE_PATH: String = DIALOGUE_DIRECTORY + "/dialogues.zip.tmp"

const SCHEMA_VERSION: int = 1
const FILE_TEMPLATE: String = "voter_{topic}_dialog_{personality}_{index}.json"
const INDEX_WIDTH: int = 2


static func build() -> Error:
	var scan_result: Dictionary = _scan_dialogues()
	if scan_result.is_empty():
		return ERR_INVALID_DATA

	var content_version: int = _get_latest_existing_version() + 1
	var manifest: Dictionary = _build_manifest(scan_result, content_version)
	var manifest_text: String = JSON.stringify(manifest, "  ") + "\n"
	var dialogue_files: Array[String] = scan_result["files"]

	_remove_file_if_exists(TEMP_ARCHIVE_PATH)
	_remove_file_if_exists(TEMP_MANIFEST_PATH)

	var archive_error: Error = _write_archive(manifest_text, dialogue_files)
	if archive_error != OK:
		_remove_file_if_exists(TEMP_ARCHIVE_PATH)
		return archive_error

	var manifest_file := FileAccess.open(TEMP_MANIFEST_PATH, FileAccess.WRITE)
	if manifest_file == null:
		_remove_file_if_exists(TEMP_ARCHIVE_PATH)
		return FileAccess.get_open_error()
	manifest_file.store_string(manifest_text)
	manifest_file.close()

	if DirAccess.rename_absolute(TEMP_ARCHIVE_PATH, ARCHIVE_PATH) != OK:
		_remove_file_if_exists(TEMP_MANIFEST_PATH)
		return ERR_CANT_CREATE
	if DirAccess.rename_absolute(TEMP_MANIFEST_PATH, MANIFEST_PATH) != OK:
		return ERR_CANT_CREATE

	print(
		"[DIALOGUE PACKAGER] Built content version %d with %d dialogue files."
		% [content_version, dialogue_files.size()]
	)
	return OK


static func _scan_dialogues() -> Dictionary:
	var file_pattern := RegEx.new()
	if file_pattern.compile("^voter_(.+)_dialog_([a-z0-9_]+)_([0-9]{2})\\.json$") != OK:
		return {}

	var files: Array[String] = []
	var indexes: Dictionary = {}
	var personalities: Dictionary = {}

	for file_name in DirAccess.get_files_at(CONTENT_DIRECTORY):
		var match_result: RegExMatch = file_pattern.search(file_name)
		if match_result == null:
			continue

		var dialogue_data = JSON.parse_string(
			FileAccess.get_file_as_string(CONTENT_DIRECTORY.path_join(file_name))
		)
		if not dialogue_data is Dictionary:
			push_error("[DIALOGUE PACKAGER] Invalid JSON file: %s" % file_name)
			return {}

		var topic: String = match_result.get_string(1)
		var personality: String = match_result.get_string(2)
		var index: int = int(match_result.get_string(3))
		var key: String = "%s|%s" % [topic, personality]
		if not indexes.has(key):
			indexes[key] = []
		indexes[key].append(index)
		personalities[personality] = true
		files.append(file_name)

	if files.is_empty():
		push_error("[DIALOGUE PACKAGER] No numbered dialogue JSON files were found.")
		return {}

	files.sort()
	var counts: Dictionary = {}
	for key_variant in indexes:
		var key: String = str(key_variant)
		var separator: int = key.find("|")
		var topic: String = key.left(separator)
		var personality: String = key.substr(separator + 1)
		var topic_indexes: Array = indexes[key_variant]
		topic_indexes.sort()
		for offset in topic_indexes.size():
			if int(topic_indexes[offset]) != offset + 1:
				push_error(
					"[DIALOGUE PACKAGER] %s/%s must be numbered consecutively from 01."
					% [topic, personality]
				)
				return {}

		if not counts.has(topic):
			counts[topic] = {}
		counts[topic][personality] = topic_indexes.size()

	var personality_names: Array[String] = []
	for personality_variant in personalities:
		personality_names.append(str(personality_variant))
	personality_names.sort()

	return {
		"counts": counts,
		"files": files,
		"personalities": personality_names,
	}


static func _build_manifest(scan_result: Dictionary, content_version: int) -> Dictionary:
	var sorted_dialogues: Dictionary = {}
	var topics: Array = scan_result["counts"].keys()
	topics.sort()
	for topic_variant in topics:
		var topic: String = str(topic_variant)
		var sorted_personality_counts: Dictionary = {}
		var topic_counts: Dictionary = scan_result["counts"][topic_variant]
		var personality_names: Array = topic_counts.keys()
		personality_names.sort()
		for personality_variant in personality_names:
			sorted_personality_counts[personality_variant] = topic_counts[personality_variant]
		sorted_dialogues[topic] = sorted_personality_counts

	return {
		"schema_version": SCHEMA_VERSION,
		"content_version": content_version,
		"content_label": "build-%d" % content_version,
		"minimum_game_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"filename": {
			"template": FILE_TEMPLATE,
			"index_width": INDEX_WIDTH,
		},
		"personalities": scan_result["personalities"],
		"dialogues": sorted_dialogues,
	}


static func _write_archive(manifest_text: String, dialogue_files: Array[String]) -> Error:
	var packer := ZIPPacker.new()
	var error: Error = packer.open(TEMP_ARCHIVE_PATH)
	if error != OK:
		return error

	error = _write_archive_entry(packer, "manifest.json", manifest_text.to_utf8_buffer())
	if error != OK:
		packer.close()
		return error

	for file_name in dialogue_files:
		error = _write_archive_entry(
			packer,
			file_name,
			FileAccess.get_file_as_bytes(CONTENT_DIRECTORY.path_join(file_name))
		)
		if error != OK:
			packer.close()
			return error

	return packer.close()


static func _write_archive_entry(
	packer: ZIPPacker,
	file_name: String,
	contents: PackedByteArray
) -> Error:
	var error: Error = packer.start_file(file_name)
	if error != OK:
		return error
	error = packer.write_file(contents)
	if error != OK:
		return error
	return packer.close_file()


static func _get_latest_existing_version() -> int:
	var latest_version: int = 0
	if FileAccess.file_exists(MANIFEST_PATH):
		var manifest_data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if manifest_data is Dictionary:
			latest_version = maxi(latest_version, int(manifest_data.get("content_version", 0)))

	if FileAccess.file_exists(ARCHIVE_PATH):
		var reader := ZIPReader.new()
		if reader.open(ARCHIVE_PATH) == OK:
			if reader.file_exists("manifest.json"):
				var archive_manifest = JSON.parse_string(
					reader.read_file("manifest.json").get_string_from_utf8()
				)
				if archive_manifest is Dictionary:
					latest_version = maxi(
						latest_version,
						int(archive_manifest.get("content_version", 0))
					)
			reader.close()
	return latest_version


static func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
