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
var _symbol_textures: Array = []
var _stage: Stage = null

var _current_occupancy: Array = []
var _current_queue_count: int = 0

#data containers
const HUD_PATH: String = "res://!project/art/UI/HUD/"
var _waiting_stops: Array = [3, 4, 5, 6, 7, 9, 12]
var _progress_indices: Array = [0, 1, 2, 3, 4, 5, 6]
var _symbol_indices: Array = [0, 1, 2, 3, 4, 5, 6]
var _symbol_names: Array = ["UV", "ID", "Check", "Spray", "Ballot", "Vote", "Box"]

#onready vars
@onready var _hbox_progress: HBoxContainer = $CenterContainer/VBoxContainer/HBoxProgress
@onready var _hbox_symbols: HBoxContainer = $CenterContainer/VBoxContainer/HBoxSymbols

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	####_init_symbol_textures()
	_init_outline_materials()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

func init(stage: Stage) -> void:
	_stage = stage
	_stage.queue_count_updated.connect(_on_queue_count_updated)
	_stage.stops_occupancy_updated.connect(_on_stops_occupancy_updated)

	_current_occupancy = _stage.voting_course.map(func(stop): return not stop.is_free())
	_current_queue_count = _stage._active_voters.size()
	_update_ui()

func _on_stops_occupancy_updated(stop_occupancy: Array) -> void:
	_current_occupancy = stop_occupancy
	_update_ui()

func _on_queue_count_updated(count: int) -> void:
	_current_queue_count = count
	_update_ui()

func _update_ui() -> void:
	for i in _waiting_stops.size():
		var stop_index: int = _waiting_stops[i]
		var occupied: bool = false
		if stop_index < _current_occupancy.size():
			occupied = _current_occupancy[stop_index]
		_indicators[i].material.set_shader_parameter("enabled_outline", occupied)

	_update_symbols()

func _update_symbols() -> void:
	for i in _waiting_stops.size():
		var behind_count: int = _count_consecutive_behind(i)
		var color: String = "green"
		if behind_count >= 3:
			color = "red"
		elif behind_count >= 2:
			color = "yellow"

		if i < _symbol_textures.size():
			_symbol_textures[i]["node"].texture = _symbol_textures[i]["textures"][color]

func _count_consecutive_behind(index: int) -> int:
	var count: int = 0
	var i: int = index - 1
	while i >= 0:
		var stop_index: int = _waiting_stops[i]
		if stop_index < _current_occupancy.size() and _current_occupancy[stop_index]:
			count += 1
			i -= 1
		else:
			break
	if index == 0 or (count > 0 and i < 0):
		count += _current_queue_count
	return count

func _init_outline_materials() -> void:
	var symbol_children: Array = _hbox_symbols.get_children()
	for i in _symbol_indices.size():
		var symbol: TextureRect = symbol_children[_symbol_indices[i]]
		symbol.material = symbol.material.duplicate()
		symbol.material.set_shader_parameter("enabled_outline", false)
		_indicators.append(symbol)

func _init_symbol_textures() -> void:
	var symbol_children: Array = _hbox_symbols.get_children()
	for i in _symbol_names.size():
		var textures: Dictionary = {
			"green": load(HUD_PATH + _symbol_names[i] + " - green.png"),
			"yellow": load(HUD_PATH + _symbol_names[i] + " - yellow.png"),
			"red": load(HUD_PATH + _symbol_names[i] + " - red.png"),
		}
		_symbol_textures.append({
			"node": symbol_children[_symbol_indices[i]],
			"textures": textures,
		})
