##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Full-screen info dialog overlay
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name InfoDialog
extends CanvasLayer

#signals
signal dialog_closed

#private vars
var _info_file: FileAccess = FileAccess.open("res://!project/build/design/info_texts.json", FileAccess.READ)
var _info_data: Dictionary = {}
var _tweening: Tween = null
var _is_closed: bool = false

var _cool_info: FileAccess = FileAccess.open("res://!project/build/design/cool_infos.json", FileAccess.READ)
var _cool_data: Dictionary = {}

var _secs_per_char: float = 0.06

#onready vars
@onready var background: ColorRect = %Background
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %Title
@onready var content_label: RichTextLabel = %Content

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_load_info_texts()

#consumes input, closes dialog
func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_closed:
		return
	#closes dialog on "start", "right" or "wrong" press
	if event.is_action_pressed("start") or event.is_action_pressed("right") or event.is_action_pressed("wrong"):
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

#direct dictionary lookup, falling back to a manual case-insensitive search
func _get_info_key(search_key: String) -> String:
	if _info_data.has(search_key):
		return search_key
	for key in _info_data:
		if key.to_lower() == search_key.to_lower():
			return key
	return ""

#shows dialog with content based on voting stop
func show_info(vote_stop_name: String) -> void:
	var key := _get_info_key(vote_stop_name)
	if key.is_empty():
		return

	_set_content(key)
	visible = true
	await _opening_animation()
	_unveil_text()

#sets dialog components' content
func _set_content(key: String) -> void:
	var data: Dictionary = _cool_data if owner.cool_game else _info_data
	title_label.text = data[key]["title"]
	content_label.text = "[center]" + data[key]["content"] + "[/center]"
	content_label.visible_ratio = 0.0

#open animation: background fades in, panel scales up with overshoot
func _opening_animation() -> void:
	background.color.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)

	#wait one frame so layout computes panel size for correct pivot
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0

	#tweens in parallel: background fades, panel fades and scales
	var open_tween := create_tween().set_parallel(true)
	open_tween.tween_property(background, "color:a", 0.5, 0.3) \
		.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(panel, "modulate:a", 1.0, 0.35) \
		.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(panel, "scale", Vector2.ONE, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await open_tween.finished

#show text, fixed time/char
func _unveil_text() -> void:
	if _tweening:
		_tweening.kill()
	_tweening = create_tween()
	var time_for_char: float = _secs_per_char # s/c
	#total time in seconds for the full text to appear
	var duration: float = content_label.text.length() * time_for_char
	#tweening visible_ratio (char count) from 0 to 1 over the duration
	_tweening.tween_property(content_label, "visible_ratio", 1.0, duration)

#stops tween, plays exit animation
func _close_dialog() -> void:
	if _is_closed:
		return
	_is_closed = true

	if _tweening:
		_tweening.kill()
		_tweening = null

	await _closing_animation()
	visible = false
	_is_closed = false
	#signals dialog close
	#course continuation
	dialog_closed.emit()

#exit animation: panel shrinks and fades, background fades out
func _closing_animation() -> void:
	#tweens in parallel: panel fades and scales down, background fades out
	var close_tween := create_tween().set_parallel(true)
	close_tween.tween_property(panel, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN)
	close_tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	close_tween.tween_property(background, "color:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_IN)

	await close_tween.finished

#SIGNALS
#███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
#██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
#███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
#╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
#███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
#╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝

func _on_close_button_pressed() -> void:
	_close_dialog()
