##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Start screen with the ballot box, entry point, shake the phone (drag the ballot box up/down on web) or click play 3 times to start
#maintainer      : Zeljko, Nemanja
#version         : 1.0
#===============================================================================
class_name StartScreen
extends Control

#m/s² fed while a key is held on PC debug builds, comfortably over Configs.Shake["shake_threshold"]
const _FAKE_ACCEL: float = 25.0
#m/s², resting value on the device z axis, used to fake the accelerometer on PC debug builds
const _RESTING_GRAVITY: float = 9.8
#top row inside the unrotated card, px
const _TOP_CHOICE_BOUNDS: Rect2 = Rect2(20.0, 110.0, 304.0, 58.0)
#px from one row top to the next, row height plus gap
const _ROW_CHOICE_SPACING: float = 66.0
#clip mask alpha above which the ballot is drawn
const _MASK_ALPHA_THRESHOLD: float = 0.5

#private vars
var _is_starting: bool = false
var _chosen_difficulty: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL
var _shake_done: bool = false
var _shake_count: int = 0
var _click_count: int = 0
#+1 up, -1 down, 0 resting; direction of the movement currently over threshold
var _shake_direction: float = 0.0
var _last_shake_time: int = 0
var _slogan_jumping_animation: Tween
var _rest_slogan_offset: float
#web only: ballot box dragged up/down by pointer stands in for the shake
var _is_dragging: bool = false
#+1 up, -1 down, 0 within threshold; direction of the drag last counted as a shake
var _ballot_dragging_direction: float = 0.0
var _ballot_dragging_origin: float = 0.0
var _box_resting_position: float = 0.0
var _box_snapping_animation: Tween
#stretches all timing once the matrix rain opens; Configs.Shake["sequence_slowdown"] in debug builds, 1.0 otherwise
var _sequence_slowdown: float = 1.0
var _clip_mask_pixels: Image

#onready vars
@onready var jumper: CenterContainer = %JumperContainer
@onready var jump_sound: AudioStreamPlayer = %JumpSound
@onready var vote_animation: AnimationPlayer = %VoteAnimation
@onready var ballot_box_selection: Control = %BallotBoxSelection
@onready var masked_ballot: NinePatchRect = %MaskedBallot
@onready var ballot_card: Node2D = %Card
@onready var click_button: Button = %ClickButton
@onready var click_counter_label: Label = %ClickCounterLabel
@onready var matrix_overlay: ColorRect = %MatrixOverlay
@onready var digits_overlay: ColorRect = %DigitsOverlay
@onready var init_line_label: Label = %InitLineLabel
@onready var follow_students_label: Label = %FollowStudentsLabel
@onready var start_difficulty: StartDifficultyManager = %Difficulty
@onready var button_leaderboard: Control = %LeaderboardButton
@onready var start_button: Control = %StartButton

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

#starts the jump sound looping as soon as the menu loads
func _ready() -> void:
	_rest_slogan_offset = jumper.position.y
	_clip_mask_pixels = masked_ballot.texture.get_image()
	_init_web_drag()

	click_button.pressed.connect(_on_click_button_pressed)
	jump_sound.finished.connect(_on_jump_sound_finished)
	jump_sound.play()

	start_difficulty.initialize(_chosen_difficulty)
	start_difficulty.difficulty_changed.connect(_on_difficulty_changed)
	button_leaderboard.gui_input.connect(_on_leaderboard_button_input)
	start_button.gui_input.connect(_on_start_button_input)

#counts up/down phone movements via accelerometer, starts game on enough shakes
func _process(_delta: float) -> void:
	if _is_starting: return

	_simulate_accelerometer_on_pc()

	var vertical_acceleration: float = Input.get_accelerometer().y
	var current_direction: float = 0.0
	if absf(vertical_acceleration) > Configs.Shake["shake_threshold"]:
		current_direction = signf(vertical_acceleration)
	#one shake = one new movement over threshold, up or down alone or a direct up/down flip
	if current_direction != 0.0 and current_direction != _shake_direction:
		_count_phone_shake(current_direction)
	_shake_direction = current_direction

#starts game on "start" press as well
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_start_game()
		#input consumed, no tree propagation
		get_viewport().set_input_as_handled()

#emits the tapped row's choice; touch only, mouse clicks arrive as emulated touch
func _gui_input(event: InputEvent) -> void:
	if _is_starting: return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event or not touch_event.pressed: return

	var row_index: int = _find_tapped_choice(touch_event.position)
	if row_index < 0: return

	Signals.menu_option_selected.emit(row_index as Globals.MainMenu)
	accept_event()

#signal BallotBoxSelection.gui_input => drags the ballot box up/down and snaps it back, web only
func _on_ballot_dragged(event: InputEvent) -> void:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button.pressed and not _is_starting:
			_begin_ballot_dragging(mouse_button.global_position.y)
		elif not mouse_button.pressed and _is_dragging:
			_release_dragged_artwork()
		accept_event()
		return

	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion and _is_dragging:
		_move_dragged_artwork(mouse_motion.global_position.y)
		accept_event()

#signal ClickButton.pressed => counts clicks, jumps the text; starts the game on enough of them
func _on_click_button_pressed() -> void:
	if _is_starting: return

	_click_count += 1
	#every click shows the 3, never the running count, growing with each click
	var click_font_sizes: Array = Configs.Shake["click_font_sizes"]
	click_counter_label.text = str(Configs.Shake["click_count"])
	click_counter_label.add_theme_font_size_override(&"font_size", click_font_sizes[mini(_click_count, click_font_sizes.size()) - 1])
	_jump_slogan(1.0)
	if _click_count >= Configs.Shake["click_count"]:
		#clicks stop counting now, the last 3 stays in sight a moment before the start sequence
		_is_starting = true
		_hide_start_screen_choices()
		await get_tree().create_timer(Configs.Shake["click_pause"]).timeout
		_finish_start_sequence()

#signal Difficulty.difficulty_changed => keeps the difficulty the game starts with
func _on_difficulty_changed(difficulty: GameDescriptor.Difficulty) -> void:
	_chosen_difficulty = difficulty

#signal LeaderboardButton.gui_input => opens the leaderboard on touch or click
func _on_leaderboard_button_input(event: InputEvent) -> void:
	if _is_starting: return

	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.go_to_leaderboard()

#signal StartButton.gui_input => starts the game at once on touch or click, skipping the start sequence
func _on_start_button_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_start_game()

#loops the jump sound until the shake sequence is done, then counts down to the game
func _on_jump_sound_finished() -> void:
	if _shake_done:
		_play_countdown()
	else:
		jump_sound.play()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#maps a screen point onto the moving card; row index under it, -1 when off the rows or hidden in the box
func _find_tapped_choice(screen_position: Vector2) -> int:
	if not _is_point_unmasked(screen_position): return -1

	var card_position: Vector2 = ballot_card.get_global_transform_with_canvas().affine_inverse() * screen_position
	for row_index: int in Globals.MainMenu.size():
		var choice_bounds: Rect2 = _TOP_CHOICE_BOUNDS
		choice_bounds.position.y += row_index * _ROW_CHOICE_SPACING
		if choice_bounds.has_point(card_position): return row_index
	return -1

#true where the clip mask lets the ballot show, i.e. above the box slot
func _is_point_unmasked(screen_position: Vector2) -> bool:
	var masked_position: Vector2 = masked_ballot.get_global_transform_with_canvas().affine_inverse() * screen_position
	if not Rect2(Vector2.ZERO, masked_ballot.size).has_point(masked_position): return false

	#the mask's top pixel row is stretched upwards over the ballot area above the box
	var stretched_height: int = int(masked_ballot.size.y) - _clip_mask_pixels.get_height()
	var mask_pixel: Vector2i = Vector2i(int(masked_position.x), maxi(int(masked_position.y) - stretched_height, 0))
	if not Rect2i(Vector2i.ZERO, _clip_mask_pixels.get_size()).has_point(mask_pixel): return false
	return _clip_mask_pixels.get_pixelv(mask_pixel).a > _MASK_ALPHA_THRESHOLD

#browsers expose no reliable accelerometer; the ballot box is dragged up/down by pointer instead
func _init_web_drag() -> void:
	if not OS.has_feature("web"): return

	_box_resting_position = ballot_box_selection.position.y
	ballot_box_selection.mouse_filter = Control.MOUSE_FILTER_STOP
	ballot_box_selection.gui_input.connect(_on_ballot_dragged)

#grabs the ballot box: stops any snap-back and marks where the pointer pressed as the drag origin
func _begin_ballot_dragging(pointer_position: float) -> void:
	if _box_snapping_animation: _box_snapping_animation.kill()

	_is_dragging = true
	_ballot_dragging_direction = 0.0
	_ballot_dragging_origin = pointer_position

#moves the ballot box along the pointer; each new direction past the threshold counts as a shake
func _move_dragged_artwork(pointer_position: float) -> void:
	var drag_limit: float = Configs.Shake["drag_limit"]
	var drag_distance: float = clampf(_ballot_dragging_origin - pointer_position, -drag_limit, drag_limit)
	ballot_box_selection.position.y = _box_resting_position - drag_distance

	if _is_starting or absf(drag_distance) < Configs.Shake["drag_threshold"]: return
	var current_direction: float = signf(drag_distance)
	if current_direction != _ballot_dragging_direction:
		_ballot_dragging_direction = current_direction
		_count_phone_shake(current_direction)

#snaps the ballot box back to rest; a counted drag also counts the return as a shake the other way
func _release_dragged_artwork() -> void:
	_is_dragging = false
	if _ballot_dragging_direction != 0.0 and not _is_starting:
		_count_phone_shake(-_ballot_dragging_direction)
	_ballot_dragging_direction = 0.0

	_box_snapping_animation = create_tween()
	_box_snapping_animation.tween_property(ballot_box_selection, "position:y", _box_resting_position, Configs.Shake["jump_duration"]) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

#counts one up/down movement, jumps the text; starts the game on enough of them within the timeout
func _count_phone_shake(direction: float) -> void:
	var current_time: int = Time.get_ticks_msec()
	if current_time - _last_shake_time > Configs.Shake["timeout"]:
		_shake_count = 0

	_shake_count += 1
	_last_shake_time = current_time
	_jump_slogan(direction)
	if _shake_count >= Configs.Shake["shake_count"]:
		_finish_start_sequence()

#stops counting shakes and clicks; game starts once the sound finishes this last loop
func _finish_start_sequence() -> void:
	_shake_done = true
	_is_starting = true
	click_button.disabled = true
	_hide_start_screen_choices()
	#final count shows the 3 while the last sound plays out
	click_counter_label.text = str(Configs.Shake["click_count"])
	#debug builds stretch the last sound, text and countdown alike
	if OS.is_debug_build():
		_sequence_slowdown = Configs.Shake["sequence_slowdown"]
	jump_sound.pitch_scale = 1.0 / _sequence_slowdown
	#ballot stops moving and stays still while the last sound plays out
	vote_animation.pause()
	#screen turns to matrix rain until the game loads
	matrix_overlay.show()

	#matrix text shows its first line, then swaps to the second one
	init_line_label.show()
	var init_line_tween: Tween = create_tween()
	init_line_tween.tween_interval(Configs.Shake["init_line_duration"] * _sequence_slowdown)
	init_line_tween.tween_callback(init_line_label.hide)
	init_line_tween.tween_callback(follow_students_label.show)

#start sequence is under way, difficulty, leaderboard and instant start can no longer be picked
func _hide_start_screen_choices() -> void:
	start_difficulty.hide()
	button_leaderboard.hide()
	start_button.hide()

#shows 1, 2 and 3 over everything, each for its own digit_durations entry, then starts the game
func _play_countdown() -> void:
	var digits_material: ShaderMaterial = digits_overlay.material as ShaderMaterial
	var digit_durations: Array = Configs.Shake["digit_durations"]
	var digit_opacities: Array = Configs.Shake["digit_opacities"]
	digits_overlay.show()

	var countdown_tween: Tween = create_tween()
	for digit: int in range(1, 4):
		countdown_tween.tween_callback(digits_material.set_shader_parameter.bind(&"digit", digit))
		countdown_tween.tween_callback(digits_material.set_shader_parameter.bind(&"opacity", digit_opacities[digit - 1]))
		countdown_tween.tween_property(digits_material, "shader_parameter/progress", 1.0, digit_durations[digit - 1] * _sequence_slowdown).from(0.0)
	countdown_tween.tween_callback(GameManager.start_game.bind(_chosen_difficulty, MissionDescriptor.new()))

#no-op on mobile and in release builds, hardware sensors take over there
#Up/Down arrow held = phone moved up/down
func _simulate_accelerometer_on_pc() -> void:
	if not (OS.has_feature("pc") and OS.is_debug_build()): return

	var y: float = 0.0
	if Input.is_key_pressed(KEY_UP):   y =  _FAKE_ACCEL
	if Input.is_key_pressed(KEY_DOWN): y = -_FAKE_ACCEL
	Input.set_accelerometer(Vector3(0.0, y, _RESTING_GRAVITY))

#bounces the text along the shake direction (+1 up, -1 down) and back to rest
func _jump_slogan(direction: float) -> void:
	if _slogan_jumping_animation: _slogan_jumping_animation.kill()

	jump_sound.play()

	var rest_position: float = _rest_slogan_offset
	var peak_position: float = rest_position - direction * Configs.Shake["jump_height"]
	var jump_duration: float = Configs.Shake["jump_duration"]

	_slogan_jumping_animation = create_tween()
	_slogan_jumping_animation.tween_property(jumper, "position:y", peak_position, jump_duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slogan_jumping_animation.tween_property(jumper, "position:y", rest_position, jump_duration * 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

#starts the game through GameManager so it switches to the main game screen
func _start_game() -> void:
	if _is_starting: return
	_is_starting = true

	GameManager.start_game(_chosen_difficulty, MissionDescriptor.new())
