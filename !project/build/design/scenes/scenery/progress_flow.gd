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

const OUTLINE_SHADER: Shader = preload("res://!project/art/shaders/outline.gdshader")

#private vars
var _buttons: Array = []
var _indicator_alert_threshold: int = 3
var _indicator_warning_threshold: int = 2
#Classic controls outline the stops occupied by voters instead of the stop buttons alone
var _is_outlined: bool = false

var _stage: Stage = null
var _waiting_stops: Array = []

var _queued_voters: int = 0
var _stops_occupancy: Array = []

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
	#Help stays clickable while the game is frozen, so it can close the help it opened
	$CenterContainer/VBoxContainer/HBoxContainer/HelpSlot/Help.process_mode = Node.PROCESS_MODE_ALWAYS
	#browsers can't close the tab from the game, quit() is a no-op there
	if OS.has_feature("web"):
		%Close.hide()

#signal Help.pressed => requests the intro text
func _on_help_pressed() -> void:
	Signals.help_requested.emit()

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
		button.pressed.connect(_on_stop_button_pressed.bind(_buttons.size()))
		_buttons.append(button)

#inits stops outline, each stop button gets its own outline material
func _init_indicators() -> void:
	for button in _buttons:
		var outline_material: ShaderMaterial = ShaderMaterial.new()
		outline_material.shader = OUTLINE_SHADER
		outline_material.set_shader_parameter("outline_color", Color(0.33333325, 1, 0, 1))
		outline_material.set_shader_parameter("outline_width", 120.0)
		outline_material.set_shader_parameter("enabled_outline", false)
		outline_material.set_shader_parameter("modulate_color", Color.WHITE)
		button.material = outline_material

#inits setups, called from game
func init(stage: Stage, controller_type: Globals.ControllerType) -> void:
	_stage = stage
	_is_outlined = controller_type == Globals.ControllerType.Classic
	if _is_outlined:
		_init_indicators()
	#stage signals' reactions
	_stage.queue_count_updated.connect(_on_queue_count_updated)
	_stage.stops_occupancy_updated.connect(_on_stops_occupancy_updated)

	#inits local vars
	_set_waiting_stops()
	_set_queued_voters()
	_set_stops_occupancy()

	#inits progress update
	_update_buttons()
	_highlight_indicators()

#identifies waiting stops list
func _set_waiting_stops() -> void:
	_waiting_stops = []
	for i in _stage.voting_course.size():
		if _stage.voting_course[i].get("is_stop"):
			_waiting_stops.append(i)

#counts queued (waiting) voters
func _set_queued_voters() -> void:
	_queued_voters = _stage.queued_voters.size()

#identifies occupied stops (list)
func _set_stops_occupancy() -> void:
	_stops_occupancy = []
	for stop in _stage.voting_course:
		_stops_occupancy.append(not stop.is_free())

#signal stage.queue_count_updated.emit() => refresh controls and outline
func _on_queue_count_updated(count: int) -> void:
	_queued_voters = count
	_update_buttons()
	_highlight_indicators()

#signal stage.stops_occupancy_updated.emit() => refresh controls and outline
func _on_stops_occupancy_updated(occupancy: Array) -> void:
	_stops_occupancy = occupancy
	call_deferred("_update_buttons")
	_highlight_indicators()

#outline indicators occupied by voters, Classic controls only
func _highlight_indicators() -> void:
	if not _is_outlined: return

	for idx in min(_buttons.size(), _waiting_stops.size()):
		var stop_index: int = _waiting_stops[idx]
		var stop_occupied: bool = false
		if stop_index < _stops_occupancy.size():
			stop_occupied = _stops_occupancy[stop_index]
		#sets indicator outline using stop's availability
		_buttons[idx].material.set_shader_parameter("enabled_outline", stop_occupied)
		#visualises stop density
		_indicate_bottleneck(idx)

#modulate indicators color based on voters
func _indicate_bottleneck(idx: int) -> void:
	var voters_waiting: int = _count_voters_waiting(idx)
	if voters_waiting >= _indicator_alert_threshold:
		_buttons[idx].material.set_shader_parameter("modulate_color", Configs.BottleneckIndicators["alert_indicator_color"])
	elif voters_waiting >= _indicator_warning_threshold:
		_buttons[idx].material.set_shader_parameter("modulate_color", Configs.BottleneckIndicators["warning_indicator_color"])
	else:
		_buttons[idx].material.set_shader_parameter("modulate_color", Color.WHITE)

#count voters waiting behind a given stop (idx)
func _count_voters_waiting(idx: int) -> int:
	var count: int = 0
	var index: int = idx - 1
	while index >= 0:
		var stop_index: int = _waiting_stops[index]
		if stop_index < _stops_occupancy.size() and _stops_occupancy[stop_index]:
			count += 1
			index -= 1
		else:
			break
	if idx == 0 or (count > 0 and index < 0):
		count += _queued_voters
	return count

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
