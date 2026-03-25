extends CanvasLayer

var _indicators: Array = []
var _waiting_stops: Array = [3, 4, 5, 6, 7, 9, 12]
var _progress_indices: Array = [0, 1, 2, 3, 4, 5, 7]
var _symbol_indices: Array = [0, 1, 2, 3, 4, 5, 7]
var _symbol_names: Array = ["UV", "ID", "Check", "Spray", "Ballot", "Vote", "Box"]
var _symbol_textures: Array = []

const HUD_PATH: String = "res://!project/art/UI/HUD/"

@onready var _hbox_progress: HBoxContainer = $CenterContainer/VBoxContainer/HBoxProgress
@onready var _hbox_symbols: HBoxContainer = $CenterContainer/VBoxContainer/HBoxSymbols
var _voting_course: Array = []
var _stage: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	_stage = get_parent().get_node("Stage")
	if _stage:
		_voting_course = _stage.get_node("Scenery/VoterStops").get_children()

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

	var progress_children: Array = _hbox_progress.get_children()
	for i in _progress_indices.size():
		var slot: Control = progress_children[_progress_indices[i]]
		var indicator: ColorRect = ColorRect.new()
		indicator.color = Color.RED
		indicator.custom_minimum_size = Vector2(40, 20)
		indicator.size = Vector2(40, 20)
		indicator.visible = false
		slot.add_child(indicator)
		_indicators.append(indicator)

func _process(_delta: float) -> void:
	for i in _waiting_stops.size():
		var stop_index: int = _waiting_stops[i]
		var occupied: bool = false
		if stop_index < _voting_course.size():
			occupied = not _voting_course[stop_index].is_free()
		_indicators[i].visible = occupied

		var behind_count: int = _count_consecutive_behind(i)
		var color: String = "green"
		if behind_count >= 3:
			color = "red"
		elif behind_count >= 2:
			color = "yellow"
		_symbol_textures[i]["node"].texture = _symbol_textures[i]["textures"][color]

func _count_consecutive_behind(index: int) -> int:
	var count: int = 0
	var i: int = index - 1
	while i >= 0:
		var stop_index: int = _waiting_stops[i]
		if stop_index < _voting_course.size() and not _voting_course[stop_index].is_free():
			count += 1
			i -= 1
		else:
			break
	if index == 0 or (count > 0 and i < 0):
		if _stage:
			count += _stage._active_voters.size()
	return count
