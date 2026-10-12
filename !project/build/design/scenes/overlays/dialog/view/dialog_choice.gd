class_name DialogChoice
extends Control

@onready var _text: RichTextLabel = $ChoiceText
@onready var _background: NinePatchRect = $NinePatchRect

#colour of the speaker answering, the highlight is a shade of it
var _fill_color: Color = DialogColors.get_default_color()
var _is_highlighted: bool = false
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

#fills the answer with the answering speaker colour, text contrasting it
func set_fill(fill_color: Color) -> void:
	_fill_color = fill_color
	_show_fill()

#shades the answer within its speaker colours while the Confirm button would submit it
func set_highlighted(is_highlighted: bool) -> void:
	_is_highlighted = is_highlighted
	_show_fill()

#paints the background in the speaker colour or its highlight shade, with contrasting text
func _show_fill() -> void:
	var shown_fill: Color = DialogColors.get_highlight_color(_fill_color) if _is_highlighted else _fill_color
	_background.modulate = shown_fill
	DialogColors.apply_text_colors(_text, shown_fill)

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
