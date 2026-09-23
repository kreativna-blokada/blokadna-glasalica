##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Main menu, entry point, shake the phone (drag it up/down on web) to start
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name MainMenu
extends Control

#m/s² fed while a key is held on PC debug builds, comfortably over Configs.Shake["shake_threshold"]
const _FAKE_ACCEL: float = 25.0
#m/s², resting value on the device z axis, used to fake the accelerometer on PC debug builds
const _GRAVITY: float = 9.8

#private vars
var _is_starting: bool = false
var _shake_done: bool = false
var _shake_count: int = 0
#+1 up, -1 down, 0 resting; direction of the movement currently over threshold
var _shake_direction: float = 0.0
var _last_shake_time: int = 0
var _jump_tween: Tween
var _rest_offset: float
#web only: phone dragged up/down by pointer stands in for the shake
var _is_dragging: bool = false
#+1 up, -1 down, 0 within threshold; direction of the drag last counted as a shake
var _drag_direction: float = 0.0
var _drag_origin: float = 0.0
var _phone_resting: float = 0.0
var _phone_tween: Tween

#onready vars
@onready var jumper: CenterContainer = %JumperContainer
@onready var jump_sound: AudioStreamPlayer = %JumpSound
@onready var phone_animation: AnimationPlayer = %PhoneAnimation
@onready var phone_container: TextureRect = %Phone

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

#starts the jump sound looping as soon as the menu loads
func _ready() -> void:
	_rest_offset = jumper.position.y
	_init_web_drag()

	jump_sound.finished.connect(_on_jump_sound_finished)
	jump_sound.play()

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
		_register_shake(current_direction)
	_shake_direction = current_direction

#starts game on "start" press as well
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_start_game()
		#input consumed, no tree propagation
		get_viewport().set_input_as_handled()

#signal Phone.gui_input => drags the phone up/down and snaps it back, web only
func _on_phone_input(event: InputEvent) -> void:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button.pressed and not _is_starting:
			_start_phone_image_drag(mouse_button.global_position.y)
		elif not mouse_button.pressed and _is_dragging:
			_release_phone_image()
		accept_event()
		return

	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion and _is_dragging:
		_drag_phone_image(mouse_motion.global_position.y)
		accept_event()

#loops the jump sound until the shake sequence is done, then starts the game
func _on_jump_sound_finished() -> void:
	if _shake_done:
		get_tree().change_scene_to_file(Globals.Scenes[Globals.Scene.Game]["path"])
	else:
		jump_sound.play()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#browsers expose no reliable accelerometer; the phone is dragged up/down by pointer instead
func _init_web_drag() -> void:
	if not OS.has_feature("web"): return

	_phone_resting = phone_container.position.y
	phone_container.mouse_filter = Control.MOUSE_FILTER_STOP
	phone_container.gui_input.connect(_on_phone_input)

#grabs the phone: stops any snap-back and marks where the pointer pressed as the drag origin
func _start_phone_image_drag(pointer_position: float) -> void:
	if _phone_tween: _phone_tween.kill()

	_is_dragging = true
	_drag_direction = 0.0
	_drag_origin = pointer_position

#moves the phone along the pointer; each new direction past the threshold counts as a shake
func _drag_phone_image(pointer_position: float) -> void:
	var drag_limit: float = Configs.Shake["drag_limit"]
	var drag_distance: float = clampf(_drag_origin - pointer_position, -drag_limit, drag_limit)
	phone_container.position.y = _phone_resting - drag_distance

	if _is_starting or absf(drag_distance) < Configs.Shake["drag_threshold"]: return
	var current_direction: float = signf(drag_distance)
	if current_direction != _drag_direction:
		_drag_direction = current_direction
		_register_shake(current_direction)

#snaps the phone back to rest; a counted drag also counts the return as a shake the other way
func _release_phone_image() -> void:
	_is_dragging = false
	if _drag_direction != 0.0 and not _is_starting:
		_register_shake(-_drag_direction)
	_drag_direction = 0.0

	_phone_tween = create_tween()
	_phone_tween.tween_property(phone_container, "position:y", _phone_resting, Configs.Shake["jump_duration"]) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

#counts one up/down movement, jumps the text; starts the game on enough of them within the timeout
func _register_shake(direction: float) -> void:
	var current_time: int = Time.get_ticks_msec()
	if current_time - _last_shake_time > Configs.Shake["timeout"]:
		_shake_count = 0

	_shake_count += 1
	_last_shake_time = current_time
	_jump(direction)
	if _shake_count >= Configs.Shake["count"]:
		#stop counting; game starts once the sound finishes this last loop
		_shake_done = true
		_is_starting = true
		#phone stops looping and stays still while the last sound plays out
		phone_animation.play(&"final")

#no-op on mobile and in release builds, hardware sensors take over there
#Up/Down arrow held = phone moved up/down
func _simulate_accelerometer_on_pc() -> void:
	if not (OS.has_feature("pc") and OS.is_debug_build()): return

	var y: float = 0.0
	if Input.is_key_pressed(KEY_UP):   y =  _FAKE_ACCEL
	if Input.is_key_pressed(KEY_DOWN): y = -_FAKE_ACCEL
	Input.set_accelerometer(Vector3(0.0, y, _GRAVITY))

#bounces the text along the shake direction (+1 up, -1 down) and back to rest
func _jump(direction: float) -> void:
	if _jump_tween: _jump_tween.kill()

	jump_sound.play()

	var rest_position: float = _rest_offset
	var peak_position: float = rest_position - direction * Configs.Shake["jump_height"]
	var jump_duration: float = Configs.Shake["jump_duration"]

	_jump_tween = create_tween()
	_jump_tween.tween_property(jumper, "position:y", peak_position, jump_duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(jumper, "position:y", rest_position, jump_duration * 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

#switches to the main game scene via Globals registry
func _start_game() -> void:
	if _is_starting: return
	_is_starting = true

	get_tree().change_scene_to_file(Globals.Scenes[Globals.Scene.Game]["path"])
