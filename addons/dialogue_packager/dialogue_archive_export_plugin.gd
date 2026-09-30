@tool
extends EditorExportPlugin

const ARCHIVE_PATH: String = "res://!project/build/design/dialogues/dialogues.zip"


func _get_name() -> String:
	return "DialogueArchiveExportPlugin"


func _export_begin(
	_features: PackedStringArray,
	_is_debug: bool,
	_path: String,
	_flags: int
) -> void:
	if not FileAccess.file_exists(ARCHIVE_PATH):
		push_error("[DIALOGUE PACKAGER] dialogues.zip is missing. Build it before exporting.")
		return
	add_file(ARCHIVE_PATH, FileAccess.get_file_as_bytes(ARCHIVE_PATH), false)
