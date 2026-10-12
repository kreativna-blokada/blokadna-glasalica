class_name TextPopup
extends Control

@onready var text : RichTextLabel = $Container/Text
@onready var _next_explanation: HBoxContainer = $Container/Legend/NextExplanation
@onready var _classic_explanations: Array[HBoxContainer] = [$Container/Legend/LeftCornerPair, $Container/Legend/RightCornerPair]

signal finished()

func set_text(_text: String) -> void:
	text.text = _text

func init(controller_type: Globals.ControllerType) -> void:
	var is_classic: bool = controller_type == Globals.ControllerType.Classic
	_next_explanation.visible = not is_classic
	for classic_explanation in _classic_explanations:
		classic_explanation.visible = is_classic


func _on_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		finished.emit()
