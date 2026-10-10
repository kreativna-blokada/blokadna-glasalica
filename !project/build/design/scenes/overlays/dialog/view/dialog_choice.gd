class_name DialogChoice
extends Control

@onready var _text: RichTextLabel = $ChoiceText
@onready var _background: NinePatchRect = $NinePatchRect

#background look from the scene, restored when the highlight leaves
var _original_background_modulate: Color
#pre-zoom answers are at most two lines tall
var _is_compact: bool = false

signal choice_clicked(sender: DialogChoice);

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

func set_text(text: String) -> void:
	_text.text = text


# number of wrapped lines the choice text takes, at least 1
func get_num_lines() -> int:
	#### if _text.get_line_count() > 1:
	#### 	return 2
	#### return 1
	var line_count: int = maxi(1, _text.get_line_count())
	if _is_compact:
		return mini(line_count, Configs.DialogueZoom["compact_answer_max_lines"])
	return line_count

#### brings back the pre-zoom answer font and line limit, re-using 153f7a2 - 60e239c
func use_compact_look() -> void:
	_is_compact = true
	_text.theme = load(Configs.DialogueZoom["compact_theme"])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_background_modulate = _background.modulate

#tints the background while the Confirm button would submit this answer
func set_highlighted(is_highlighted: bool) -> void:
	_background.modulate = Configs.ClassicalControllers["highlighted_answer_tint"] if is_highlighted else _original_background_modulate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _touch_debounce_timer > 0:
		_touch_debounce_timer -= delta
	pass

func _on_click_detector_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return

	# forward the event upwards
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		choice_clicked.emit(self)
		_touch_debounce_timer = TOUCH_DEBOUNCE_TIME
