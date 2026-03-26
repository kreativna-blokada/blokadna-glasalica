##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Full-screen info dialog overlay
#author          : Zeljko Vulovic
#date            : 20260325
#version         : 1.0
#===============================================================================
class_name DialogOverlay
extends CanvasLayer


signal dialog_closed

@onready var title_label: Label = %Title
@onready var content_label: Label = %Content

var _info_data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_info_texts()


func _load_info_texts() -> void:
	var file := FileAccess.open("res://!project/build/design/info_texts.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_info_data = json.data


func show_info(stop_name: String) -> void:
	var key := _find_key(stop_name)
	if key.is_empty():
		return
	title_label.text = _info_data[key]["title"]
	content_label.text = _info_data[key]["content"]
	visible = true


func _find_key(stop_name: String) -> String:
	if _info_data.has(stop_name):
		return stop_name
	for key in _info_data:
		if key.to_lower() == stop_name.to_lower():
			return key
	return ""


func _close_dialog() -> void:
	visible = false
	dialog_closed.emit()


func _on_close_button_pressed() -> void:
	_close_dialog()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("start"):
		_close_dialog()
		get_viewport().set_input_as_handled()
