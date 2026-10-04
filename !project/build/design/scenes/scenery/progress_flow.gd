##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Progress flow overlay
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
class_name ProgressFlow
extends CanvasLayer

#signals
signal stop_button_pressed(stop_name: String, stop_index: int)

#private vars
var _buttons: Array = []

var _stage: Stage = null
var _waiting_stops: Array = []

#onready vars
@onready var _progress_stops: HBoxContainer = $CenterContainer/VBoxContainer/HBoxContainer

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_init_buttons()
	#browsers can't close the tab from the game, quit() is a no-op there
	if OS.has_feature("web"):
		%Close.hide()

#signal Close.pressed => requests closing the game screen
func _on_close_pressed() -> void:
	Signals.game_close_requested.emit()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#inits progress buttons
func _init_buttons() -> void:
	for idx in _progress_stops.get_child_count():
		var button: TextureButton = _progress_stops.get_child(idx) as TextureButton
		if button == null:
			continue
		button.disabled = true
		button.pressed.connect(_on_stop_button_pressed.bind(idx))
		_buttons.append(button)

#inits setups, called from game
func init(stage: Stage) -> void:
	_stage = stage
	#stage signals' reactions
	_stage.queue_count_updated.connect(_on_queue_count_updated)
	_stage.stops_occupancy_updated.connect(_on_stops_occupancy_updated)

	#inits local vars
	_set_waiting_stops()

	#inits progress update
	_update_buttons()

#identifies waiting stops list
func _set_waiting_stops() -> void:
	_waiting_stops = []
	for i in _stage.voting_course.size():
		if _stage.voting_course[i].get("is_stop"):
			_waiting_stops.append(i)

#signal stage.queue_count_updated.emit() => refresh controls
func _on_queue_count_updated(_count: int) -> void:
	_update_buttons()

#signal stage.stops_occupancy_updated.emit() => refresh controls
func _on_stops_occupancy_updated(_occupancy: Array) -> void:
	call_deferred("_update_buttons")

#enables only buttons where a voter is currently stopped
func _update_buttons() -> void:
	for idx in min(_buttons.size(), _waiting_stops.size()):
		var stop_index: int = _waiting_stops[idx]
		_buttons[idx].disabled = not _has_stopped_voter_at_stop(stop_index)

#checks if a voter is stopped at the stage stop index
func _has_stopped_voter_at_stop(stop_index: int) -> bool:
	return _stage != null and _stage.get_stopped_voter_at_stop(stop_index) != null

#emits selected stop data for gameplay handlers
func _on_stop_button_pressed(idx: int) -> void:
	if idx >= _waiting_stops.size():
		return

	var stop_index: int = _waiting_stops[idx]
	if stop_index >= _stage.voting_course.size():
		return

	stop_button_pressed.emit(str(_stage.voting_course[stop_index].name), stop_index)
