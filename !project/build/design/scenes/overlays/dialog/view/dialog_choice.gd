class_name DialogChoice
extends Control

@onready var _text: RichTextLabel = $ChoiceText
@onready var _background: NinePatchRect = $NinePatchRect

#background look from the scene, restored when the highlight leaves
var _original_background_modulate: Color
#colour and opacity of the answer nine-slice texture inside its border
const BACKGROUND_TEXTURE_COLOR: Color = Color8(189, 180, 168, 137)
#text colour of the speaker answering and the sentence box showing through the answer
var _answer_text_color: Color = DialogColors.get_default_color()
var _sentence_box_color: Color = DialogColors.get_default_color()
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

#height of the wrapped answer text in px
func get_text_height() -> float:
	return _text.get_content_height()

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
	_show_text_colors()

#prints the answer in the text colour of the speaker answering, shaded for the sentence box under it
func set_text_colors(answer_text_color: Color, sentence_box_color: Color) -> void:
	_answer_text_color = answer_text_color
	_sentence_box_color = sentence_box_color
	_show_text_colors()

#shades the text against the answer background as drawn, the tinted texture blended over the sentence box
func _show_text_colors() -> void:
	var answer_fill: Color = BACKGROUND_TEXTURE_COLOR * _background.modulate
	var answer_background: Color = _sentence_box_color.lerp(Color(answer_fill, 1.0), answer_fill.a)
	DialogColors.apply_text_colors(_text, _answer_text_color, answer_background)

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
