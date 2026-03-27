##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Full-screen info dialog overlay
#author          : Zeljko Vulovic
#date            : 20260325
#version         : 1.0
#===============================================================================
class_name InfoDialog
extends CanvasLayer

#signals
signal dialog_closed

#private vars
var _info_file: FileAccess = FileAccess.open("res://!project/build/design/info_texts.json", FileAccess.READ)
var _info_data: Dictionary = {}
var _tween: Tween = null

var _cool_info: FileAccess = FileAccess.open("res://!project/build/design/cool_infos.json", FileAccess.READ)
var _cool_data: Dictionary = {}

#onready vars
@onready var title_label: Label = %Title
@onready var content_label: Label = %Content

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	#input and tweens working, if tree gets paused
	#process_mode = Node.PROCESS_MODE_ALWAYS
	_load_info_texts()

#consumes input, closes dialog on "start" press
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("start"):
		_close_dialog()
		#input consumed, no tree propagation
		get_viewport().set_input_as_handled()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#loads from json files to dictionaries
func _load_info_texts() -> void:
	_info_data = _parse_json_file(_info_file)
	_cool_data = _parse_json_file(_cool_info)

func _parse_json_file(file: FileAccess) -> Dictionary:
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			return json.data
	return {}

#shows dialog with content based on voting stop
func show_info(vote_stop_name: String) -> void:
	var key := _get_info_key(vote_stop_name)
	if key.is_empty():
		return

	_set_content(key)
	visible = true
	_unveil_text()

#sets dialog components' content
func _set_content(key: String) -> void:
	var data: Dictionary = _cool_data if owner.cool_game else _info_data
	title_label.text = data[key]["title"]
	content_label.text = data[key]["content"]
	content_label.visible_ratio = 0.0

#show text, fixed time/char
func _unveil_text() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var time_for_char: float = 0.06 # seconds per char
	#total time in seconds for the full text to appear
	var duration: float = content_label.text.length() * time_for_char
	#tweening visible_ratio (char count) from 0 to 1 over the duration
	_tween.tween_property(content_label, "visible_ratio", 1.0, duration)

#direct dictionary lookup, falling back to a manual case-insensitive search
func _get_info_key(search_key: String) -> String:
	if _info_data.has(search_key):
		return search_key
	for key in _info_data:
		if key.to_lower() == search_key.to_lower():
			return key
	return ""

#stops tween, emits dialog_closed
func _close_dialog() -> void:
	if _tween:
		_tween.kill()
		_tween = null

	visible = false
	dialog_closed.emit()

#SIGNALS
#███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
#██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
#███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
#╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
#███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
#╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝

func _on_close_button_pressed() -> void:
	_close_dialog()
