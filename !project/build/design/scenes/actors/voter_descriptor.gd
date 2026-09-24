class_name VoterDescriptor

var _personality: String = ""
var _dialog_paths: Dictionary = {}
var _content_version: int = 0

func _init(personality: String, dialog_paths: Dictionary, content_version: int = 0) -> void:
	_personality = personality
	_dialog_paths = dialog_paths.duplicate()
	_content_version = content_version
	
func get_dialog_path(stop_name: String) -> String:
	return str(_dialog_paths.get(stop_name.to_snake_case(), ""))

func get_personality() -> String:
	return _personality

func get_content_version() -> int:
	return _content_version
