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
#px the I, T and B team letters sink, and their shadow shrinks, while held
const _TEAM_LETTER_PRESS_DEPTH: int = 2
#seconds of silence between the B team letter sound and the alert sound once I, T and B are pressed in that order
const _TEAM_SEQUENCE_ALERT_GAP: float = 0.3
#team member name each of the I, T and B team letters glitches
const _TEAM_LETTER_NAMES: Dictionary[StringName, String] = {&"LetterI": "Марија М.", &"LetterT": "Марко М.", &"LetterB": "Жељко В."}
#matrix rain characters the glitched name letters turn into
const _MATRIX_GLYPHS: String = "0123456789Z:.\"=*+-<>¦|"
#seconds between two scrambles of the glitched name
const _NAME_GLITCH_STEP: float = 0.05
#scrambles before the glitched name is restored
const _NAME_GLITCH_STEPS: int = 7

#exported vars
@export_group("Main Menu")
#controls the start screen opens with; the controls row switches it at runtime
@export var controller_type: Globals.ControllerType = Globals.ControllerType.Classic
#difficulty the start screen opens with; the difficulty row switches it at runtime
@export var difficulty_type: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL

@export_group("Debug Settings")
#game opens right away without intro
@export var skip_intro: bool = false
@export_group("")

#private vars
var _is_starting: bool = false
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
#ClickCounterLabel text and font size from the scene, shown before the first click
var _rest_click_caption: String
var _rest_click_fontsize: int
#shadow offset of the I, T and B team letters from the scene, px
var _rest_letter_shadow: int
#team list text from the scene, the glitched name is restored from it
var _rest_team_text: String
#team letters pressed so far in the I, T, B order
var _team_sequence_count: int = 0
#scrambles a team member name for a moment, then restores it
var _name_glitch_animation: Tween
#ms tick of the latest difficulty switch, arrow taps closer than Configs.MenuDifficulty["tap_debounce"] to it are ignored
var _arrow_switch_moment: int = 0
#player id shown after the ИНДЕКС word, fully or still unveiling
var _is_player_id_shown: bool = false
var _player_id_unveiling_animation: Tween
#colour sweeping over the play button left to right while it is held
var _hold_fill_animation: Tween
#quick colour sweep over the play button up to the share of the counted clicks
var _click_fill_animation: Tween
#share of the play button filled so far, kept between holds
var _hold_fill_share: float = 0.0
#the current play button press counted up by holding, so its release is no click
var _is_hold_counted: bool = false
#swells and dies out the jump sound volume
var _jump_sound_fading_animation: Tween

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
@onready var team_label: RichTextLabel = %TeamLabel
@onready var id_label: Label = %IdLabel
@onready var id_reveal_button: Button = %IdRevealButton
@onready var web_version_box: VBoxContainer = %WebVersionBox
@onready var music_controller: TextureButton = %MusicController
@onready var zoom_controller: TextureButton = %ZoomController
@onready var team_letters: Array[Label] = [$TeamLabel/ITglouriousBasterds/LetterI, $TeamLabel/ITglouriousBasterds/LetterT, $TeamLabel/ITglouriousBasterds/LetterB]
@onready var team_alert_sound: AudioStreamPlayer = $TeamLabel/ITglouriousBasterds/AlertSound
@onready var thrones: Thrones = %Thrones

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

#sets up the menu; the jump sound stays silent until the first click, hold or shake
func _ready() -> void:
	_rest_slogan_offset = jumper.position.y
	_rest_click_caption = click_counter_label.text
	_rest_click_fontsize = click_counter_label.get_theme_font_size(&"font_size")
	info_label.text = _get_menu_description(_menu_choice)
	id_label.text = Literals.ID_WORD
	#the web build is the version the box points to, so it has nothing to point to there
	web_version_box.visible = not OS.has_feature("web")
	_load_game_start_count()
	hand_hint.visible = _is_hint_scheduled()
	_show_side_words(not hand_hint.visible)
	if GameManager.is_returning_home(): _rest_card_on_leaderboard()

	menu_option_button.pressed.connect(_on_menu_option_button_pressed)
	menu_option_button.gui_input.connect(_on_menu_option_button_input)
	jump_sound.finished.connect(_on_jump_sound_finished)

	left_arrow.gui_input.connect(_on_arrow_input)
	right_arrow.gui_input.connect(_on_arrow_input)
	Signals.menu_option_selected.connect(_on_menu_option_selected)

	#the button shows whether sound was switched off before the menu loaded
	music_controller.set_pressed_no_signal(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master")))
	music_controller.toggled.connect(_on_music_controller_switched)
	id_reveal_button.pressed.connect(_switch_player_id)
	#a Label ignores taps by default, the ИНДЕКС word has to catch them to switch the player id
	id_label.mouse_filter = Control.MOUSE_FILTER_STOP
	id_label.gui_input.connect(_on_id_label_input)

	_rest_letter_shadow = team_letters[0].get_theme_constant(&"shadow_offset_x")
	_rest_team_text = team_label.text
	for team_letter: Label in team_letters:
		team_letter.gui_input.connect(_on_team_letter_input.bind(team_letter))

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

#starts game on "initiate" press as well
func _unhandled_input(event: InputEvent) -> void:
	if _is_starting: return

	if event.is_action_pressed("initiate"):
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

#signal MenuOptionButton.pressed => counts clicks, a hold already counted itself; the leaderboard row only opens the leaderboard, the difficulty and controls rows only show their choice
func _on_menu_option_button_pressed() -> void:
	if _is_starting or _is_hold_counted or _menu_choice in [Globals.MainMenu.Leaderboard, Globals.MainMenu.Difficulty, Globals.MainMenu.Controls]: return

	_count_start_press(_click_count + 1)
	_sweep_click_fill()

#sweeps the play button fill up to the share of the counted clicks, from wherever it is
func _sweep_click_fill() -> void:
	var counted_share: float = minf(float(_click_count) / Configs.Shake["click_count"], 1.0)
	if counted_share <= _hold_fill_share: return

	if _hold_fill_animation: _hold_fill_animation.kill()
	if _click_fill_animation: _click_fill_animation.kill()
	_click_fill_animation = create_tween()
	_click_fill_animation.tween_method(_set_hold_fill, _hold_fill_share, counted_share, Configs.Shake["click_fill_duration"])

#fills the play button left to right from where the last hold stopped, the whole of it taking the hold duration, counting up like a click each click_count share of it
func _start_hold_fill() -> void:
	_is_hold_counted = false
	if _hold_fill_share >= 1.0: return

	var click_count: int = Configs.Shake["click_count"]
	var hold_duration: float = Configs.Shake["hold_duration"]
	var resumed_share: float = _hold_fill_share

	if _hold_fill_animation: _hold_fill_animation.kill()
	if _click_fill_animation: _click_fill_animation.kill()
	_hold_fill_animation = create_tween()
	for held_count: int in range(1, click_count + 1):
		var share_end: float = float(held_count) / click_count
		if share_end <= resumed_share: continue
		var share_begin: float = maxf(resumed_share, float(held_count - 1) / click_count)
		_hold_fill_animation.tween_method(_set_hold_fill, share_begin, share_end, (share_end - share_begin) * hold_duration)
		_hold_fill_animation.tween_callback(_count_held_share.bind(held_count))

#stops the play button fill where the hold was let go
func _stop_hold_fill() -> void:
	if _hold_fill_animation: _hold_fill_animation.kill()

#one more click_count share of the hold reached: counts up like a click once it is past the clicks before it; only the first count of a hold restarts the jump sound
func _count_held_share(held_count: int) -> void:
	if held_count <= _click_count: return

	var is_first_count: bool = not _is_hold_counted
	_is_hold_counted = true
	_count_start_press(held_count, is_first_count)

#moves the fill edge over the play button and its caption, which turns white under it
func _set_hold_fill(fill_share: float) -> void:
	_hold_fill_share = fill_share
	var fill_edge: float = menu_option_button.size.x * fill_share
	(menu_option_button.material as ShaderMaterial).set_shader_parameter(&"fill_edge", fill_edge)
	(click_counter_label.material as ShaderMaterial).set_shader_parameter(&"fill_edge", fill_edge)

#shows the press count on the button, jumps the text, restarting the jump sound unless told to let it play on; starts the game on enough of them
func _count_start_press(press_count: int, is_sound_restarted: bool = true) -> void:
	_click_count = press_count
	_show_button_caption()
	_jump_slogan(1.0, is_sound_restarted)
	if _click_count >= Configs.Shake["click_count"]:
		#clicks stop counting, the last 3 stays in sight a moment before the start sequence
		_is_starting = true
		_hide_start_screen_choices()
		await get_tree().create_timer(Configs.Shake["click_pause"]).timeout
		_finish_start_sequence()

####signal Difficulty.difficulty_changed => keeps the difficulty the game starts with
####func _on_difficulty_changed(difficulty: GameDescriptor.Difficulty) -> void:
####	_chosen_difficulty = difficulty

#signal MusicController.toggled => mutes every sound in the game while pressed, unmutes it when released
func _on_music_controller_switched(is_sound_off: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), is_sound_off)

#signal IdLabel.gui_input => a tap on the ИНДЕКС word switches the player id the same as IdRevealButton; touch only, mouse clicks arrive as emulated touch
func _on_id_label_input(event: InputEvent) -> void:
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event or not touch_event.pressed: return

	_switch_player_id()
	accept_event()

#signal LetterI/LetterT/LetterB.gui_input => plays the letter sound, glitches its team member name, counts it towards the I, T, B order and sinks the letter, shrinking its shadow, while the finger holds it, lifts it back on release; touch only, mouse clicks arrive as emulated touch
func _on_team_letter_input(event: InputEvent, team_letter: Label) -> void:
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event: return

	var letter_shadow: int = _rest_letter_shadow - _TEAM_LETTER_PRESS_DEPTH if touch_event.pressed else _rest_letter_shadow
	team_letter.add_theme_constant_override(&"shadow_offset_x", letter_shadow)
	team_letter.add_theme_constant_override(&"shadow_offset_y", letter_shadow)
	#the container puts the letter back in its row on release
	if touch_event.pressed:
		team_letter.position += Vector2.ONE * _TEAM_LETTER_PRESS_DEPTH
		(team_letter.get_node(^"LetterSound") as AudioStreamPlayer).play()
		_glitch_team_name(_TEAM_LETTER_NAMES[team_letter.name])
		_advance_team_sequence(team_letter)
	else:
		(team_letter.get_parent() as Container).queue_sort()
	accept_event()

#counts the team letter towards the I, T, B order, crumbles the team letters into the throne after the B sound and a short gap once the order is complete
func _advance_team_sequence(team_letter: Label) -> void:
	if team_letter == team_letters[_team_sequence_count]:
		_team_sequence_count += 1
	else:
		_team_sequence_count = 1 if team_letter == team_letters[0] else 0
	if _team_sequence_count < team_letters.size(): return

	_team_sequence_count = 0
	var letter_sound: AudioStreamPlayer = team_letter.get_node(^"LetterSound")
	get_tree().create_timer(letter_sound.stream.get_length() + _TEAM_SEQUENCE_ALERT_GAP).timeout.connect(_crumble_team_into_throne)

#while the team row still shows, swaps the team, web version and slogan letters for pixel points slice glitching, vanishing and crumbling into the throne for as long as the alert sound is heard, then plays the alert sound so both start together
func _crumble_team_into_throne() -> void:
	if team_label.visible:
		thrones.crumble(team_label, slogan_label, web_version_box, team_alert_sound.stream.get_length() - Configs.Thrones["silent_tail"])
		team_label.hide()
		slogan_label.hide()
		web_version_box.hide()

	team_alert_sound.play()

#scrambles and recolours the team member name with matrix rain characters a few times, then restores the team list
func _glitch_team_name(team_name: String) -> void:
	if _name_glitch_animation: _name_glitch_animation.kill()
	_name_glitch_animation = create_tween()
	for glitch_step: int in _NAME_GLITCH_STEPS:
		_name_glitch_animation.tween_callback(_scramble_team_name.bind(team_name))
		_name_glitch_animation.tween_interval(_NAME_GLITCH_STEP)
	_name_glitch_animation.tween_callback(team_label.set_text.bind(_rest_team_text))

#swaps 1 or 2 random letters of the team member name for matrix rain characters in the team list, coloured like the I, T and B team letters
func _scramble_team_name(team_name: String) -> void:
	var glitched_name: String = team_name
	for swapped_letter: int in randi_range(1, 2):
		var letter_index: int = randi() % team_name.length()
		while team_name[letter_index] in " .":
			letter_index = randi() % team_name.length()
		glitched_name[letter_index] = _MATRIX_GLYPHS[randi() % _MATRIX_GLYPHS.length()]
	var letter_colour: String = team_letters[0].get_theme_color(&"font_color").to_html(false)
	team_label.text = _rest_team_text.replace(team_name, "[color=#%s]%s[/color]" % [letter_colour, glitched_name])

#signal IdRevealButton.pressed => unveils the player id when hidden, otherwise brings back the lone ИНДЕКС word
func _switch_player_id() -> void:
	if _is_player_id_shown:
		_hide_player_id()
	else:
		_reveal_player_id()

#hides the glyph and unveils the player id letter by letter after the ИНДЕКС word, at the dialogue speed
func _reveal_player_id() -> void:
	_is_player_id_shown = true
	id_reveal_button.hide()
	id_label.text = Literals.ID_CAPTION % LeaderboardManager.get_player_id()

	var shown_letter_count: int = Literals.ID_WORD.length()
	var total_letter_count: int = id_label.text.length()
	id_label.visible_characters = shown_letter_count
	var unveil_duration: float = (total_letter_count - shown_letter_count) / Configs.IdReveal["unveil_speed"]
	_player_id_unveiling_animation = create_tween()
	_player_id_unveiling_animation.tween_property(id_label, "visible_characters", total_letter_count, unveil_duration)

#stops any unveiling and shows the lone ИНДЕКС word and the glyph again, as before the first tap
func _hide_player_id() -> void:
	_is_player_id_shown = false
	id_reveal_button.show()
	if _player_id_unveiling_animation: _player_id_unveiling_animation.kill()
	id_label.text = Literals.ID_WORD
	id_label.visible_characters = -1

#signal LeftArrow.gui_input, RightArrow.gui_input => switches the difficulty or the controls of the ticked row and shows it on the MenuOptionButton; touch only, mouse clicks arrive as emulated touch; taps right after a switch are ignored
func _on_arrow_input(event: InputEvent) -> void:
	if _is_starting: return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event or not touch_event.pressed: return
	var current_moment: int = Time.get_ticks_msec()
	if current_moment - _arrow_switch_moment < Configs.MenuDifficulty["tap_debounce"] * 1000.0: return

	_arrow_switch_moment = current_moment
	SoundManager.play_stinger(Globals.Sound.MenuSelect)
	if _menu_choice == Globals.MainMenu.Controls:
		controller_type = Globals.ControllerType.Screen if controller_type == Globals.ControllerType.Classic else Globals.ControllerType.Classic
	else:
		difficulty_type = GameDescriptor.Difficulty.NORMAL if difficulty_type == GameDescriptor.Difficulty.EASY else GameDescriptor.Difficulty.EASY
	_show_button_caption()
	accept_event()

#signal MenuOptionButton.gui_input => opens the leaderboard on touch while the leaderboard row is ticked; on the starting row a touch held fills the button and letting go stops the fill; touch only, mouse clicks arrive as emulated touch
func _on_menu_option_button_input(event: InputEvent) -> void:
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if _is_starting or not touch_event: return

	if _menu_choice == Globals.MainMenu.Leaderboard and touch_event.pressed:
		GameManager.go_to_leaderboard()
	elif _menu_choice == Globals.MainMenu.Starting:
		if touch_event.pressed:
			_start_hold_fill()
		else:
			_stop_hold_fill()

#signal Signals.menu_option_selected => shows the hint for the menu option the ballot card has ticked; the team row shows TeamLabel in place of the hidden MenuOptionButton and InfoLabel
func _on_menu_option_selected(menu_option: Globals.MainMenu) -> void:
	#letting the card go on the row already chosen picks nothing new
	if menu_option != _menu_choice: SoundManager.play_stinger(Globals.Sound.MenuSelect)
	_menu_choice = menu_option
	#clicks and the hold fill count only on the starting row, leaving it starts them over
	if menu_option != Globals.MainMenu.Starting:
		_click_count = 0
		_set_hold_fill(0.0)
	var is_team_chosen: bool = menu_option == Globals.MainMenu.Team
	menu_option_button.visible = not is_team_chosen
	var is_selector_chosen: bool = menu_option in [Globals.MainMenu.Difficulty, Globals.MainMenu.Controls]
	left_arrow.visible = is_selector_chosen
	right_arrow.visible = is_selector_chosen
	_show_button_caption()
	#the throne stays until the team row is left, the team, slogan and web version letters come back after it
	if not is_team_chosen: thrones.clear()
	team_label.visible = is_team_chosen and not thrones.is_shown()
	slogan_label.visible = not thrones.is_shown()
	web_version_box.visible = not OS.has_feature("web") and not thrones.is_shown()
	info_label.visible = not is_team_chosen
	if not is_team_chosen: info_label.text = _get_menu_description(menu_option)

#hint for the menu option; on web the starting hint leaves out shaking the phone
func _get_menu_description(menu_option: Globals.MainMenu) -> String:
	return Literals.WEB_MENU_START_DESCRIPTION if menu_option == Globals.MainMenu.Starting and OS.has_feature("web") else Literals.MAIN_MENU_DESCRIPTIONS[menu_option]

#signal JumpSound.finished => counts down to the game once the shake sequence is done; otherwise the sound stays silent until the next click, hold or shake
func _on_jump_sound_finished() -> void:
	if _shake_done: _play_countdown()

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
	if hand_hint.visible: SoundManager.play_stinger(Globals.Sound.MenuSelect)
	hand_hint.hide()
	_show_side_words(true)
	#vote already stopped: the card stays where it rests
	if not vote_animation.is_playing(): return

	vote_animation.pause()
	_card_snapping_animation = create_tween()
	_card_snapping_animation.tween_method(_seek_vote_animation, _find_ballot_moment(ballot.position.y), _find_choice_moment(Globals.MainMenu.Starting), Configs.CardDrag["snap_duration"]) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_card_snapping_animation.tween_callback(func() -> void: _card_pointer_distance = ballot.position.y - _card_pointer_position)

#stops the vote and leaves the card still where dragging it ticks the leaderboard row, chosen without the select sound
func _rest_card_on_leaderboard() -> void:
	vote_animation.pause()
	var ballot_height: float = _find_choice_height(Globals.MainMenu.Leaderboard)
	_seek_vote_animation(_find_row_moment(ballot_height))
	ballot.position = _find_ballot_position(_find_ballot_moment(ballot_height))
	_menu_choice = Globals.MainMenu.Leaderboard
	_on_menu_option_selected(Globals.MainMenu.Leaderboard)

#ballot height in the middle of the slot depth share that ticks the menu option's row when dragging
func _find_choice_height(menu_option: Globals.MainMenu) -> float:
	var top_height: float = _find_ballot_position(_TOP_BALLOT_MOMENT).y
	return top_height + (_ROW_COUNT - 1 - menu_option + 0.5) / _ROW_COUNT * Configs.CardDrag["slot_depth"]

#middle of the row tick for the menu option on the downward vote pass
func _find_choice_moment(menu_option: Globals.MainMenu) -> float:
	return _TOP_BALLOT_MOMENT + (_ROW_COUNT - 1 - menu_option + 0.5) * _ROW_TICK_SPACING

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

#stops counting shakes and clicks; game starts once the jump sound finishes this last play, started here if already silent
func _finish_start_sequence() -> void:
	#debug builds with skip_intro ticked go straight to the game
	if skip_intro and OS.is_debug_build():
		_start_game()
		return

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
	_play_jump_sound(not jump_sound.playing)
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

#shows on ClickCounterLabel the chosen difficulty or controls while their row is ticked, the leaderboard caption on its row, otherwise the click count; every click shows the 3, never the running count, growing with each click
func _show_button_caption() -> void:
	if _menu_choice == Globals.MainMenu.Leaderboard:
		click_counter_label.text = Literals.LEADERBOARD_BUTTON_CAPTION
		click_counter_label.add_theme_font_size_override(&"font_size", _rest_click_fontsize)
	elif _menu_choice == Globals.MainMenu.Difficulty:
		click_counter_label.text = Literals.DIFFICULTY_DESCRIPTIONS[difficulty_type]
		click_counter_label.add_theme_font_size_override(&"font_size", Configs.MenuDifficulty["font_size"])
	elif _menu_choice == Globals.MainMenu.Controls:
		click_counter_label.text = Literals.CONTROLLER_DESCRIPTIONS[controller_type]
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

#bounces the text along the shake direction (+1 up, -1 down) and back to rest, restarting the jump sound unless told to let it play on
func _jump_slogan(direction: float, is_sound_restarted: bool = true) -> void:
	if _slogan_jumping_animation: _slogan_jumping_animation.kill()

	if is_sound_restarted: _play_jump_sound()

	var rest_position: float = _rest_slogan_offset
	var peak_position: float = rest_position - direction * Configs.Shake["jump_height"]
	var jump_duration: float = Configs.Shake["jump_duration"]

	_slogan_jumping_animation = create_tween()
	_slogan_jumping_animation.tween_property(jumper, "position:y", peak_position, jump_duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slogan_jumping_animation.tween_property(jumper, "position:y", rest_position, jump_duration * 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

#plays the jump sound from where it is (or the start), swelling in and dying out before its end at the current pitch
func _play_jump_sound(is_restarted: bool = true) -> void:
	if _jump_sound_fading_animation: _jump_sound_fading_animation.kill()

	var start_position: float = 0.0 if is_restarted else jump_sound.get_playback_position()
	var remaining_duration: float = (jump_sound.stream.get_length() - start_position) / jump_sound.pitch_scale
	var fade_in: float = Configs.Shake["sound_fade_in"] if is_restarted else 0.0
	var fade_out: float = minf(Configs.Shake["sound_fade_out"], remaining_duration - fade_in)

	if is_restarted:
		jump_sound.volume_linear = 0.0
		jump_sound.play()

	_jump_sound_fading_animation = create_tween()
	_jump_sound_fading_animation.tween_property(jump_sound, "volume_linear", 1.0, fade_in) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_jump_sound_fading_animation.tween_interval(remaining_duration - fade_in - fade_out)
	_jump_sound_fading_animation.tween_property(jump_sound, "volume_linear", 0.0, fade_out) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

	#### zoom_controller.button_pressed re-introduces 153f7a2 - 60e239c implementation
	GameManager.start_game(controller_type, difficulty_type, MissionDescriptor.new(), not zoom_controller.button_pressed)
