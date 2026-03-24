extends CanvasLayer

var _indicators: Array = []
var _waiting_stops: Array = [3, 4, 5, 6, 7, 9, 12]
var _progress_indices: Array = [0, 1, 2, 3, 4, 5, 7]

@onready var _hbox_progress: HBoxContainer = $CenterContainer/VBoxContainer/HBoxProgress
var _voting_course: Array = []

func _ready() -> void:
	await get_tree().process_frame
	var stage = get_parent().get_node("Stage")
	if stage:
		_voting_course = stage.get_node("VoterStops").get_children()

	var children: Array = _hbox_progress.get_children()
	for i in _progress_indices.size():
		var slot: Control = children[_progress_indices[i]]
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
		if stop_index < _voting_course.size():
			var stop: Node2D = _voting_course[stop_index]
			_indicators[i].visible = not stop.is_free()
		else:
			_indicators[i].visible = false
