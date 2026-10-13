class_name TextPopup
extends Control

@onready var text : RichTextLabel = $Container/Text
@onready var _screen_explanations: Array[HBoxContainer] = [$Container/Legend/NextExplanation, $Container/Legend/DisabledStationExplanation, $Container/Legend/CloseExplanation]
@onready var _classic_explanations: Array[HBoxContainer] = [$Container/Legend/LeftCornerPair, $Container/Legend/RightCornerPair]
@onready var _id_footer: Label = $Container/Legend/Footer/IdFooter

signal finished()

func set_text(_text: String) -> void:
	text.text = _text

func init(controller_type: Globals.ControllerType) -> void:
	var is_classic: bool = controller_type == Globals.ControllerType.Classic
	for screen_explanation in _screen_explanations:
		screen_explanation.visible = not is_classic
	for classic_explanation in _classic_explanations:
		classic_explanation.visible = is_classic

	var player_id: String = LeaderboardManager.get_player_id()
	_id_footer.text = Literals.ID_LATIN_CAPTION % player_id
	_id_footer.visible = not player_id.is_empty()


func _on_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		finished.emit()
