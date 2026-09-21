##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Main menu, entry point, shake the phone to start
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name MainMenu
extends Control

#m/s² fed while a key is held on PC debug builds, comfortably over Configs.Shake["threshold"]
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

#onready vars
@onready var jumper: CenterContainer = %JumperContainer
@onready var jump_sound: AudioStreamPlayer = %JumpSound
@onready var phone_animation: AnimationPlayer = %PhoneAnimation

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

	jump_sound.finished.connect(_on_jump_sound_finished)
	jump_sound.play()

#counts up/down phone movements via accelerometer, starts game on enough shakes
func _process(_delta: float) -> void:
	if _is_starting: return

	_simulate_accelerometer_on_pc()

	var current_time: int = Time.get_ticks_msec()
	if current_time - _last_shake_time > Configs.Shake["timeout"]:
		_shake_count = 0

	var vertical_acceleration: float = Input.get_accelerometer().y
	var current_direction: float = 0.0
	if absf(vertical_acceleration) > Configs.Shake["threshold"]:
		current_direction = signf(vertical_acceleration)
	#one shake = one new movement over threshold, up or down alone or a direct up/down flip
	if current_direction != 0.0 and current_direction != _shake_direction:
		_shake_count += 1
		_last_shake_time = current_time
		_jump(current_direction)
		if _shake_count >= Configs.Shake["count"]:
			#stop counting; game starts once the sound finishes this last loop
			_shake_done = true
			_is_starting = true
			#phone stops looping and stays still while the last sound plays out
			phone_animation.play(&"final")
	_shake_direction = current_direction

#starts game on "start" press as well
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_start_game()
		#input consumed, no tree propagation
		get_viewport().set_input_as_handled()

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
