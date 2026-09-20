class_name VoterDescriptor

const DIALOG_DIRECTORY: String = "res://!project/build/design/dialogues"

var _personality: String = ""

func _init(personality: String) -> void:
	_personality = personality
	
func get_dialog_path(stop_name: String) -> String:
	return "%s/%s_dialog_%s.json" % [DIALOG_DIRECTORY, stop_name.to_snake_case(), _personality]
