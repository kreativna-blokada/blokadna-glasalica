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

#padlock and dim wash drawn over the answer while it is locked
var _lock_overlay: Control
var _lock_tween: Tween
#sweeps the colour over a pending pick until it unlocks
var _fill_tween: Tween
#share of the pending pick width the colour has filled, left to right
var _lock_fill: float = 0.0
#the answer waits for its lock to end
var _is_locked: bool = false
#how far the padlock shackle has sprung open, 0 closed and 1 open
var _shackle_lift: float = 0.0
#picked during the lock, goes in the moment the lock ends
var _is_pending: bool = false
#the Confirm button would submit this answer
var _is_highlighted: bool = false

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

	_lock_overlay = Control.new()
	_lock_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.draw.connect(_draw_answer_lock)
	_lock_overlay.hide()
	add_child(_lock_overlay)

#dims the answer under a closed padlock for the lock time, then pops the answer open
func lock(lock_time: float) -> void:
	if _lock_tween: _lock_tween.kill()
	scale = Vector2.ONE
	modulate = Color.WHITE
	_lock_overlay.modulate = Color.WHITE
	_lock_overlay.show()
	_is_locked = true
	set_pending(false)
	_set_shackle_lift(0.0)
	_play_lock(lock_time)

#moves the end of the lock to the given seconds from now, if the answer is still locked
func shorten_lock(remaining_lock_time: float) -> void:
	if not _is_locked: return

	_play_lock(remaining_lock_time)

#marks this answer as the one picked during the lock, submitted the moment it unlocks
func set_pending(is_pending: bool) -> void:
	_is_pending = is_pending
	_show_background()

#keeps the answer dimmed for the given seconds, a pending pick sweeping its colour meanwhile, then pops the answer open
func _play_lock(lock_time: float) -> void:
	if _lock_tween: _lock_tween.kill()
	if _fill_tween: _fill_tween.kill()

	if _is_pending:
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_lock_fill, _lock_fill, 1.0, lock_time)
	else:
		_set_lock_fill(0.0)

	_lock_tween = create_tween()
	_lock_tween.tween_interval(lock_time)
	_lock_tween.tween_callback(func() -> void:
		_is_locked = false
		pivot_offset = size * 0.5)

	var pop_time: float = Configs.AnswerLock["unlock_pop_time"]
	var flash_color: Color = Color.WHITE * Configs.AnswerLock["unlock_flash_brightness"]
	flash_color.a = 1.0
	_lock_tween.tween_method(_set_shackle_lift, 0.0, 1.0, Configs.AnswerLock["padlock_open_time"]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lock_tween.parallel().tween_property(self, "scale", Vector2.ONE * Configs.AnswerLock["unlock_bounce_scale"], pop_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_lock_tween.parallel().tween_property(self, "modulate", flash_color, pop_time)
	_lock_tween.chain().tween_property(self, "scale", Vector2.ONE, pop_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_lock_tween.parallel().tween_property(self, "modulate", Color.WHITE, pop_time)
	_lock_tween.parallel().tween_property(_lock_overlay, "modulate:a", 0.0, Configs.AnswerLock["padlock_fade_time"])
	_lock_tween.chain().tween_callback(_lock_overlay.hide)

#moves the colour fill edge and redraws the lock
func _set_lock_fill(fill: float) -> void:
	_lock_fill = fill
	_lock_overlay.queue_redraw()

#opens the padlock shackle and redraws the lock
func _set_shackle_lift(lift: float) -> void:
	_shackle_lift = lift
	_lock_overlay.queue_redraw()

#washes the part of the answer the colour has not filled and draws the padlock at its right end, solid on a pending pick
func _draw_answer_lock() -> void:
	var overlay_size: Vector2 = _lock_overlay.size
	var fill_edge: float = overlay_size.x * _lock_fill
	_lock_overlay.draw_rect(Rect2(fill_edge, 0.0, overlay_size.x - fill_edge, overlay_size.y), Configs.AnswerLock["locked_wash_color"])

	var padlock_height: float = Configs.AnswerLock["padlock_height"]
	var padlock_opacity: float = 1.0 if _is_pending else Configs.AnswerLock["padlock_opacity"]
	var padlock_color: Color = Color(_answer_text_color, padlock_opacity)
	var padlock_center: Vector2 = Vector2(overlay_size.x - Configs.AnswerLock["padlock_right_offset"], overlay_size.y * 0.5)

	var body_size: Vector2 = Vector2(padlock_height * 0.8, padlock_height * 0.55)
	var body_top: float = padlock_center.y + padlock_height * 0.5 - body_size.y
	_lock_overlay.draw_rect(Rect2(padlock_center.x - body_size.x * 0.5, body_top, body_size.x, body_size.y), padlock_color)

	var shackle_radius: float = padlock_height * 0.25
	var shackle_leg: float = padlock_height * 0.12
	var shackle_width: float = padlock_height * 0.1
	var shackle_center: Vector2 = Vector2(padlock_center.x, body_top - shackle_leg - _shackle_lift * padlock_height * 0.2)
	_lock_overlay.draw_arc(shackle_center, shackle_radius, PI, TAU, 16, padlock_color, shackle_width, true)
	for leg_side in [-1.0, 1.0]:
		var leg_top: Vector2 = shackle_center + Vector2(shackle_radius * leg_side, 0.0)
		_lock_overlay.draw_line(leg_top, leg_top + Vector2(0.0, shackle_leg), padlock_color, shackle_width, true)

#tints the background while the Confirm button would submit this answer
func set_highlighted(is_highlighted: bool) -> void:
	_is_highlighted = is_highlighted
	_show_background()

#tints the background for a pending pick first, then for the Confirm highlight, otherwise keeps the scene look
func _show_background() -> void:
	if _is_pending:
		_background.modulate = Configs.AnswerLock["pending_answer_tint"]
	elif _is_highlighted:
		_background.modulate = Configs.ClassicalControllers["highlighted_answer_tint"]
	else:
		_background.modulate = _original_background_modulate
	_lock_overlay.queue_redraw()
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
