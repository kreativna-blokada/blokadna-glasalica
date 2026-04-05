##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Progress flow overlay
#author          : Zeljko Vulovic
#date            : 20260404
#version         : 1.1
#===============================================================================
extends CanvasLayer

#private vars
var _indicators: Array = []

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
	_init_indicators()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#inits indicators outline
func _init_indicators() -> void:
	for indicator in _progress_stops.get_children():
		var rect: TextureRect = indicator as TextureRect
		if rect == null:
			continue
		rect.material = rect.material.duplicate()
		rect.material.set_shader_parameter("enabled_outline", false)

		_indicators.append(rect)

#inits setups, called from game
func init(stage: Stage) -> void:
	_stage = stage
	_stage.queue_count_updated.connect(_on_queue_count_updated)
	_stage.stops_occupancy_updated.connect(_on_stops_occupancy_updated)

	_set_waiting_stops()
	_set_queued_voters()
	_set_stops_occupancy()

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

func _on_queue_count_updated(count: int) -> void:
	_queued_voters = count
	_highlight_indicators()

func _on_stops_occupancy_updated(occupancy: Array) -> void:
	_stops_occupancy = occupancy
	_highlight_indicators()

#outline indicators occupied by voters
func _highlight_indicators() -> void:
	for idx in _waiting_stops.size():
		var stop_index: int = _waiting_stops[idx]
		var stop_occupied: bool = false
		if stop_index < _stops_occupancy.size():
			stop_occupied = _stops_occupancy[stop_index]

		_indicators[idx].material.set_shader_parameter("enabled_outline", stop_occupied)

	_highlight_bottlenecks()

#modulate indicators color based on voters
func _highlight_bottlenecks() -> void:
	for idx in _waiting_stops.size():
		var voters_waiting: int = _count_voters_waiting(idx)
		if idx < _indicators.size():
			if voters_waiting >= 3:
				_indicators[idx].material.set_shader_parameter("modulate_color", Color.RED)
			elif voters_waiting >= 2:
				_indicators[idx].material.set_shader_parameter("modulate_color", Color.YELLOW)
			else:
				_indicators[idx].material.set_shader_parameter("modulate_color", Color.WHITE)

#count voters waiting behind a given stop (index)
func _count_voters_waiting(index: int) -> int:
	var count: int = 0
	var idx: int = index - 1
	while idx >= 0:
		var stop_index: int = _waiting_stops[idx]
		if stop_index < _stops_occupancy.size() and _stops_occupancy[stop_index]:
			count += 1
			idx -= 1
		else:
			break
	if index == 0 or (count > 0 and idx < 0):
		count += _queued_voters
	return count
