##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Entry point main menu screen
#maintainer      : Zeljko, Nemanja
#version         : 1.0
#===============================================================================
class_name StartScreen
extends Control

#m/s² fed while a key is held on PC debug builds, comfortably over Configs.Shake["shake_threshold"]
const _FAKE_ACCEL: float = 25.0
#m/s², resting value on the device z axis, used to fake the accelerometer on PC debug builds
const _RESTING_GRAVITY: float = 9.8
#y of the top row inside the unrotated card, px
const _TOP_CHOICE_OFFSET: float = 110.0
#px from one row top to the next, row height plus gap
const _ROW_CHOICE_SPACING: float = 66.0
#vote animation track moving the ballot in and out of the slot
const _TRACK_BALLOT_POSITION: NodePath = ^"BallotBoxSelection/MaskedBallot/BallotOrigin/Ballot:position"
#s on the vote animation where the ballot rests on top, before going down
const _TOP_BALLOT_MOMENT: float = 0.8
#s on the vote animation where the ballot reaches the deepest point in the slot
const _DEEP_BALLOT_MOMENT: float = 4.0
#s between two row ticks on the downward vote pass
const _ROW_TICK_SPACING: float = 0.64
#halvings when searching the vote animation for the moment matching a ballot height
const _SEARCH_MOMENT_ITERATIONS: int = 16
#rows on the card, ticked one after another as the ballot goes down the slot
const _ROW_COUNT: int = 5

#private vars
var _is_starting: bool = false
var _chosen_difficulty: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL
#controls picked on the controls row, not used by the game yet
var _chosen_controller: Globals.ControllerType = Globals.ControllerType.Classic
var _shake_done: bool = false
var _shake_count: int = 0
var _click_count: int = 0
#+1 up, -1 down, 0 resting; direction of the movement currently over threshold
var _shake_direction: float = 0.0
var _last_shake_time: int = 0
var _slogan_jumping_animation: Tween
var _rest_slogan_offset: float
#touch index of the finger holding the card, -1 when none
var _card_touch_index: int = -1
var _is_card_dragging: bool = false
#pointer height in BallotOrigin space where the finger went down
var _card_pressing_position: float = 0.0
#latest pointer height in BallotOrigin space
var _card_pointer_position: float = 0.0
#ballot height minus pointer height, fixed once the card has snapped to the starting row
var _card_pointer_distance: float = 0.0
var _card_snapping_animation: Tween
#stretches all timing once the matrix rain opens; Configs.Shake["sequence_slowdown"] in debug builds, 1.0 otherwise
var _sequence_slowdown: float = 1.0
#games this player started before this screen opened, kept on the device
var _game_start_count: int = 0
#menu option whose hint shows under the slogan
var _menu_choice: Globals.MainMenu = Globals.MainMenu.Starting
#InfoLabel anchor height from the scene, where every hint but the team one shows
var _rest_hint_anchor: float
#InfoLabel font size from the scene, used by every hint but the team one
var _rest_hint_font_size: int
#ClickCounterLabel text and font size from the scene, shown before the first click
var _rest_click_caption: String
var _rest_click_fontsize: int
#ms tick of the latest difficulty switch, arrow taps closer than Configs.MenuDifficulty["tap_debounce"] to it are ignored
var _arrow_switch_moment: int = 0

#onready vars
@onready var jumper: CenterContainer = %JumperContainer
@onready var slogan_label: Label = %SloganLabel
@onready var jump_sound: AudioStreamPlayer = %JumpSound
@onready var vote_animation: AnimationPlayer = %VoteAnimation
@onready var ballot: Control = $BallotBoxSelection/MaskedBallot/BallotOrigin/Ballot
@onready var masked_ballot: NinePatchRect = %MaskedBallot
@onready var ballot_origin: Control = $BallotBoxSelection/MaskedBallot/BallotOrigin
@onready var choice_highlight: Panel = $BallotBoxSelection/MaskedBallot/BallotOrigin/Ballot/Card/ChoiceHighlight
@onready var menu_option_button: Button = %MenuOptionButton
@onready var click_counter_label: Label = %ClickCounterLabel
@onready var matrix_overlay: ColorRect = %MatrixOverlay
@onready var digits_overlay: ColorRect = %DigitsOverlay
@onready var init_line_label: Label = %InitLineLabel
@onready var follow_students_label: Label = %FollowStudentsLabel
@onready var left_arrow: Control = %LeftArrow
@onready var right_arrow: Control = %RightArrow
@onready var hand_hint: TextureRect = $BallotBoxSelection/HandGestureHint
@onready var left_side_mask: TextureRect = $BallotBoxSelection/LeftSideMask
@onready var right_side_mask: TextureRect = $BallotBoxSelection/RightSideMask
@onready var info_label: Label = %InfoLabel

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
	_rest_hint_anchor = info_label.anchor_top
	_rest_hint_font_size = info_label.get_theme_font_size(&"font_size")
	_rest_click_caption = click_counter_label.text
	_rest_click_fontsize = click_counter_label.get_theme_font_size(&"font_size")
	info_label.text = _get_menu_description(_menu_choice)
	_load_game_start_count()
	hand_hint.visible = _is_hint_scheduled()
	_show_side_words(not hand_hint.visible)

	menu_option_button.pressed.connect(_on_menu_option_button_pressed)
	menu_option_button.gui_input.connect(_on_menu_option_button_input)
	jump_sound.finished.connect(_on_jump_sound_finished)
	jump_sound.play()

	left_arrow.gui_input.connect(_on_arrow_input)
	right_arrow.gui_input.connect(_on_arrow_input)
	Signals.menu_option_selected.connect(_on_menu_option_selected)

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
	if _is_starting: return

	if event.is_action_pressed("start"):
		_start_game()
		#input consumed, no tree propagation
		get_viewport().set_input_as_handled()

#hides the hand on any press right of the slogan; grabs the card on a vertical drag and emits the ticked row on release; touch only, mouse clicks arrive as emulated touch
func _gui_input(event: InputEvent) -> void:
	if _is_starting: return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event:
		if touch_event.pressed and (_is_beside_slogan(touch_event.position) or _is_ballot_touched(touch_event.position)): _snap_card_toward_starting()
		if touch_event.pressed and _card_touch_index < 0 and _is_ballot_touched(touch_event.position):
			_card_touch_index = touch_event.index
			_card_pressing_position = _find_origin_height(touch_event.position)
			_card_pointer_position = _card_pressing_position
		elif not touch_event.pressed and touch_event.index == _card_touch_index:
			_card_touch_index = -1
			if _is_card_dragging: _emit_ticked_choice()
		accept_event()
		return

	var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
	if not drag_event or drag_event.index != _card_touch_index: return

	_card_pointer_position = _find_origin_height(drag_event.position)
	if _is_card_dragging:
		_move_card_vertically()
	elif absf(_card_pointer_position - _card_pressing_position) >= Configs.CardDrag["drag_threshold"]:
		_take_card_control()
	accept_event()

#signal MenuOptionButton.pressed => counts clicks, jumps the text; starts the game on enough of them; the leaderboard row only opens the leaderboard, the difficulty and controls rows only show their choice
func _on_menu_option_button_pressed() -> void:
	if _is_starting or _menu_choice in [Globals.MainMenu.Leaderboard, Globals.MainMenu.Difficulty, Globals.MainMenu.Controls]: return

	_click_count += 1
	_show_button_caption()
	_jump_slogan(1.0)
	if _click_count >= Configs.Shake["click_count"]:
		#clicks stop counting now, the last 3 stays in sight a moment before the start sequence
		_is_starting = true
		_hide_start_screen_choices()
		await get_tree().create_timer(Configs.Shake["click_pause"]).timeout
		_finish_start_sequence()

####signal Difficulty.difficulty_changed => keeps the difficulty the game starts with
####func _on_difficulty_changed(difficulty: GameDescriptor.Difficulty) -> void:
####	_chosen_difficulty = difficulty

#signal LeftArrow.gui_input, RightArrow.gui_input => switches the difficulty or the controls of the ticked row and shows it on the MenuOptionButton; touch only, mouse clicks arrive as emulated touch; taps right after a switch are ignored
func _on_arrow_input(event: InputEvent) -> void:
	if _is_starting: return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event or not touch_event.pressed: return
	var current_moment: int = Time.get_ticks_msec()
	if current_moment - _arrow_switch_moment < Configs.MenuDifficulty["tap_debounce"] * 1000.0: return

	_arrow_switch_moment = current_moment
	if _menu_choice == Globals.MainMenu.Controls:
		_chosen_controller = Globals.ControllerType.Screen if _chosen_controller == Globals.ControllerType.Classic else Globals.ControllerType.Classic
	else:
		_chosen_difficulty = GameDescriptor.Difficulty.NORMAL if _chosen_difficulty == GameDescriptor.Difficulty.EASY else GameDescriptor.Difficulty.EASY
	_show_button_caption()
	accept_event()

#signal MenuOptionButton.gui_input => opens the leaderboard on touch while the leaderboard row is ticked; touch only, mouse clicks arrive as emulated touch
func _on_menu_option_button_input(event: InputEvent) -> void:
	if _is_starting or _menu_choice != Globals.MainMenu.Leaderboard: return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event and touch_event.pressed:
		GameManager.go_to_leaderboard()

#signal Signals.menu_option_selected => shows the hint for the menu option the ballot card has ticked; the team hint shows higher up in place of the hidden MenuOptionButton
func _on_menu_option_selected(menu_option: Globals.MainMenu) -> void:
	_menu_choice = menu_option
	#clicks count only on the starting row, leaving it starts them over
	if menu_option != Globals.MainMenu.Starting: _click_count = 0
	var is_team_chosen: bool = menu_option == Globals.MainMenu.Team
	menu_option_button.visible = not is_team_chosen
	var is_selector_chosen: bool = menu_option in [Globals.MainMenu.Difficulty, Globals.MainMenu.Controls]
	left_arrow.visible = is_selector_chosen
	right_arrow.visible = is_selector_chosen
	_show_button_caption()
	#text and font first, the label box is sized for them when it moves
	info_label.add_theme_font_size_override(&"font_size", Configs.MenuHint["team_font_size"] if is_team_chosen else _rest_hint_font_size)
	info_label.text = _get_menu_description(menu_option)
	_move_info_label(Configs.MenuHint["team_hint_anchor"] if is_team_chosen else _rest_hint_anchor)

#hint for the menu option; on web the starting hint leaves out shaking the phone
func _get_menu_description(menu_option: Globals.MainMenu) -> String:
	return Literals.WEB_MENU_START_DESCRIPTION if menu_option == Globals.MainMenu.Starting and OS.has_feature("web") else Literals.MAIN_MENU_DESCRIPTIONS[menu_option]

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

#true when the screen point lands on the ballot box or on the card rising above it
func _is_ballot_touched(screen_position: Vector2) -> bool:
	var masked_position: Vector2 = masked_ballot.get_global_transform_with_canvas().affine_inverse() * screen_position
	return Rect2(Vector2.ZERO, masked_ballot.size).has_point(masked_position)

#true when the screen point lands right of the slogan, over the ballot box side
func _is_beside_slogan(screen_position: Vector2) -> bool:
	return screen_position.x >= slogan_label.get_global_rect().end.x

#converts a screen point into a height in BallotOrigin space, where the ballot moves
func _find_origin_height(screen_position: Vector2) -> float:
	return (ballot_origin.get_global_transform_with_canvas().affine_inverse() * screen_position).y

#user grabbed the card: it follows the finger from where it rests, or from the starting row once it has snapped there
func _take_card_control() -> void:
	_is_card_dragging = true
	#card still snapping: the snap sets the finger distance once on the starting row
	if _card_snapping_animation and _card_snapping_animation.is_running(): return
	_card_pointer_distance = ballot.position.y - _card_pointer_position

#user understood the hint: hides it, reveals the box side words, stops the vote and swiftly moves the card from where it is until the starting row is ticked
func _snap_card_toward_starting() -> void:
	hand_hint.hide()
	_show_side_words(true)
	#vote already stopped: the card stays where it rests
	if not vote_animation.is_playing(): return

	vote_animation.pause()
	#middle of the starting row tick on the downward vote pass
	var starting_moment: float = _TOP_BALLOT_MOMENT + (Globals.MainMenu.Starting + 0.5) * _ROW_TICK_SPACING
	_card_snapping_animation = create_tween()
	_card_snapping_animation.tween_method(_seek_vote_animation, _find_ballot_moment(ballot.position.y), starting_moment, Configs.CardDrag["snap_duration"]) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_card_snapping_animation.tween_callback(func() -> void: _card_pointer_distance = ballot.position.y - _card_pointer_position)

#card follows the finger up and down the slot once it has snapped to the starting row; equal depth ticks each row
func _move_card_vertically() -> void:
	if _card_snapping_animation and _card_snapping_animation.is_running(): return

	var top_height: float = _find_ballot_position(_TOP_BALLOT_MOMENT).y
	var ballot_height: float = clampf(_card_pointer_position + _card_pointer_distance, top_height, top_height + Configs.CardDrag["slot_depth"])
	_seek_vote_animation(_find_row_moment(ballot_height))
	ballot.position = _find_ballot_position(_find_ballot_moment(ballot_height))
	#each row picks itself the moment it is ticked, without waiting for release; taken from the height, the highlight may not have moved yet
	var ticked_choice: Globals.MainMenu = _find_height_choice(ballot_height) as Globals.MainMenu
	if ticked_choice != _menu_choice:
		Signals.menu_option_selected.emit(ticked_choice)

#moment on the downward vote pass ticking the row for this ballot height
func _find_row_moment(ballot_height: float) -> float:
	return _TOP_BALLOT_MOMENT + (_find_tick_step(ballot_height) + 0.5) * _ROW_TICK_SPACING

#row index ticked at this ballot height, 0 = top row; the deeper the card, the higher the ticked row
func _find_height_choice(ballot_height: float) -> int:
	return _ROW_COUNT - 1 - _find_tick_step(ballot_height)

#row tick reached on the downward vote pass at this ballot height, 0 = first tick (bottom row); the slot depth is split evenly between the ticks
func _find_tick_step(ballot_height: float) -> int:
	var top_height: float = _find_ballot_position(_TOP_BALLOT_MOMENT).y
	var depth_ratio: float = clampf((ballot_height - top_height) / Configs.CardDrag["slot_depth"], 0.0, 1.0)
	return mini(floori(depth_ratio * _ROW_COUNT), _ROW_COUNT - 1)

#ballot position the vote animation gives at a moment
func _find_ballot_position(moment: float) -> Vector2:
	var vote_choreography: Animation = vote_animation.get_animation(&"vote")
	var track_index: int = vote_choreography.find_track(_TRACK_BALLOT_POSITION, Animation.TYPE_VALUE)
	return vote_choreography.value_track_interpolate(track_index, moment)

#poses the paused vote animation at a moment: ballot, highlight, tick and box labels together
func _seek_vote_animation(moment: float) -> void:
	vote_animation.seek(moment, true)

#moment on the downward vote pass where the ballot is at this height, clamped to the top and the deepest point
func _find_ballot_moment(ballot_height: float) -> float:
	var earliest_moment: float = _TOP_BALLOT_MOMENT
	var latest_moment: float = _DEEP_BALLOT_MOMENT
	for iteration: int in _SEARCH_MOMENT_ITERATIONS:
		var middle_moment: float = (earliest_moment + latest_moment) / 2.0
		if _find_ballot_position(middle_moment).y < ballot_height:
			earliest_moment = middle_moment
		else:
			latest_moment = middle_moment
	return latest_moment

#card let go: stays where it is, its ticked row becomes the menu choice; let go while still snapping, it settles on the starting row and picks nothing
func _emit_ticked_choice() -> void:
	_is_card_dragging = false
	if _card_snapping_animation and _card_snapping_animation.is_running(): return
	Signals.menu_option_selected.emit(_find_ticked_choice() as Globals.MainMenu)

#puts InfoLabel at an anchor height on the screen, keeping its size and centering; the top anchor pushes the bottom one along when moving down past it
func _move_info_label(anchor_height: float) -> void:
	info_label.set_anchor(SIDE_TOP, anchor_height, true)
	info_label.set_anchor(SIDE_BOTTOM, anchor_height, true)

#row index under the highlight and tick, 0 = top row
func _find_ticked_choice() -> int:
	return roundi((choice_highlight.position.y - _TOP_CHOICE_OFFSET) / _ROW_CHOICE_SPACING)

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
	menu_option_button.disabled = true
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

#start sequence is under way, difficulty can no longer be picked
func _hide_start_screen_choices() -> void:
	left_arrow.hide()
	right_arrow.hide()

#shows on ClickCounterLabel the chosen difficulty or controls while their row is ticked, otherwise the click count; every click shows the 3, never the running count, growing with each click
func _show_button_caption() -> void:
	if _menu_choice == Globals.MainMenu.Difficulty:
		click_counter_label.text = Literals.DIFFICULTY_DESCRIPTIONS[_chosen_difficulty]
		click_counter_label.add_theme_font_size_override(&"font_size", Configs.MenuDifficulty["font_size"])
	elif _menu_choice == Globals.MainMenu.Controls:
		click_counter_label.text = Literals.CONTROLLER_DESCRIPTIONS[_chosen_controller]
		click_counter_label.add_theme_font_size_override(&"font_size", Configs.MenuDifficulty["font_size"])
	elif _click_count == 0:
		click_counter_label.text = _rest_click_caption
		click_counter_label.add_theme_font_size_override(&"font_size", _rest_click_fontsize)
	else:
		var click_font_sizes: Array = Configs.Shake["click_font_sizes"]
		click_counter_label.text = str(Configs.Shake["click_count"])
		click_counter_label.add_theme_font_size_override(&"font_size", click_font_sizes[mini(_click_count, click_font_sizes.size()) - 1])

#shows or hides the words on the left and right box sides, kept hidden while the hand hint plays
func _show_side_words(is_shown: bool) -> void:
	left_side_mask.visible = is_shown
	right_side_mask.visible = is_shown

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
	countdown_tween.tween_callback(_start_game)

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

#reads how many games this player started; zero on the first launch
func _load_game_start_count() -> void:
	var start_record: ConfigFile = ConfigFile.new()
	if start_record.load(Configs.HandHint["plays_record"]) == OK:
		_game_start_count = int(start_record.get_value("plays", "game_start_count", 0))

#writes how many games this player started to the device
func _save_game_start_count() -> void:
	var start_record: ConfigFile = ConfigFile.new()
	start_record.set_value("plays", "game_start_count", _game_start_count)
	var save_error: Error = start_record.save(Configs.HandHint["plays_record"])
	if save_error != OK:
		push_warning("StartScreen._save_game_start_count: cannot write %s (%s)" % [Configs.HandHint["plays_record"], error_string(save_error)])

#true when the game about to start is one of Configs.HandHint["play_numbers"]
func _is_hint_scheduled() -> bool:
	var play_numbers: Array = Configs.HandHint["play_numbers"]
	return play_numbers.has(_game_start_count + 1)

#starts the game through GameManager so it switches to the main game screen
func _start_game() -> void:
	_is_starting = true
	_game_start_count += 1
	_save_game_start_count()

	GameManager.start_game(_chosen_difficulty, MissionDescriptor.new())
