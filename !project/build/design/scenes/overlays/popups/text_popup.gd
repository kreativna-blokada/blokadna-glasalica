class_name TextPopup
extends Control

@onready var text : RichTextLabel = $Container/Text
@onready var _slogan: RichTextLabel = $Container/Slogan
@onready var _screen_explanations: Array[HBoxContainer] = [$Container/Legend/NextExplanation, $Container/Legend/DisabledStationExplanation, $Container/Legend/HelpExplanation, $Container/Legend/CloseExplanation]
@onready var _classic_explanations: Array[HBoxContainer] = [$Container/Legend/LeftCornerPair, $Container/Legend/RightCornerPair]
@onready var _id_footer: Label = $Container/Footer/IdFooter

signal finished()

func _ready() -> void:
	_breathe_slogan()

#endlessly grows the slogan to Configs.Slogan breath_scale and back, around its text center
func _breathe_slogan() -> void:
	_slogan.pivot_offset = Vector2(_slogan.get_content_width(), _slogan.get_content_height()) / 2.0
	var half_breath: float = Configs.Slogan.breath_duration / 2.0
	var breath_tween: Tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath_tween.tween_property(_slogan, "scale", Vector2.ONE * Configs.Slogan.breath_scale, half_breath)
	breath_tween.tween_property(_slogan, "scale", Vector2.ONE, half_breath)

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

#signal Home.pressed => resumes the frozen game and returns to the start screen
func _on_home_pressed() -> void:
	get_tree().paused = false
	GameManager.return_home()
