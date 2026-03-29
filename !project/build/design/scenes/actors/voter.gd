##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Voter actor controller
#author          : Zeljko Vulovic
#date            : 20260210
#version         : 1.0
#===============================================================================
class_name Voter
extends Character

#signals
signal voter_queued
signal voter_stopped(vote_stop_name: String)

#private vars
var _initial_texture: Texture2D = null
var _walk_animation_name: String = "idle"
var _voting_course_pointer: int = 0
var _course_target: Node2D = null
var _state_entered: bool = false
var _is_course_finished: bool = false
var _is_shuffling: bool = false
var _feet_offset_enhancer: int = 2
var _stop_reach_threshold: float = 5.0

var _wait_frame_coord: Dictionary = {}

#broadcast variables
var voter_factory_index: int = -1
var voting_course: Array = []
var starting_spot: Node2D = null
var is_queueing: bool = false
var is_stopping: bool = false

#onready vars
@onready var vote_stop_sound: AudioStreamPlayer = $AudioStreamPlayer

@onready var hud_sprites: Array = $HUD.get_children()
@onready var status_label: Label = $Dialog/Label
@onready var dialog_sprite: Sprite2D = $Dialog

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	#await get_tree().process_frame
	##_update_course_target()

	_animation_map[State.IDLE] = "bottom-right"
	#separate the materials to control outlines independently
	character_texture.material = character_texture.material.duplicate()

func _process(_delta: float) -> void:
	if _is_course_finished or is_stopping or is_queueing or _course_target == null:
		velocity = Vector2.ZERO
	else:
		voter_movement()

	handle_input()
	handle_movement()
	handle_animations()
	set_heading()
	move_and_slide()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#handle interaction with voters
func handle_input() -> void:
	pass

#state and course progress based
func handle_movement() -> void:
	var state_check := _state

	if _is_course_finished:
		_state = State.FINISH
	elif is_stopping:
		_state = State.STOP
	elif is_queueing:
		_state = State.WAIT
	else:
		if _state == State.WAIT or _state == State.STOP:
			_state = State.IDLE
			_walk_texture_restoring()
		super.handle_movement()

	if _state != state_check:
		_state_entered = false

func handle_animations() -> void:
	if _state == State.FINISH:
		if not _state_entered:
			animation_player.play("top-left")
	elif _state == State.STOP:
		if not _state_entered:
			if not _wait_frame_coord.is_empty():
				_apply_wait_texture()
	elif _state == State.WAIT:
		if not _state_entered:
			_set_idle_texture("bottom-right")
	elif _state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		super.handle_animations()

	if not _state_entered:
		_state_entered = true

func _find_walk_animation_name() -> void:
	match _voting_course_pointer:
		0, 1, 2: _walk_animation_name = "bottom-right"
		3: _walk_animation_name = "top-right"
		4: _walk_animation_name = "top-left"
		5, 6: _walk_animation_name = "top-right"
		7, 8, 9: _walk_animation_name = "bottom-right"
		10, 11: _walk_animation_name = "bottom-left"
		12: _walk_animation_name = "top-left"
		13: _walk_animation_name = "top-right"
		14: _walk_animation_name = "bottom-left"
		15: _walk_animation_name = "bottom-right"
		_: _walk_animation_name = "idle"

func _find_wait_animation_frame_coord() -> Dictionary:
	var animation_name: String
	match _voting_course_pointer:
		0: animation_name = "bottom-right"
		4, 5, 6: animation_name = "top-left"
		7, 8: animation_name = "top-right"
		10, 13: animation_name = "top-left"
		_: return {}
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]["Animations"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == animation_name:
			return animation_setup[animation_view]["Frame Coord"]
	return {}
#todo: cleanup

func voter_movement() -> void:
	if _course_target == null: return

	var feet_offset: Vector2 = $CollisionShape2D.position * _feet_offset_enhancer
	var feet_position: Vector2 = global_position + feet_offset
	var target_position: Vector2 = _course_target.global_position
	var distance: float = feet_position.distance_to(target_position)
	if distance < _stop_reach_threshold:
		_on_stop_reach()
	else:
		var direction: Vector2 = (target_position - feet_position).normalized()
		velocity = direction * speed

func _on_stop_reach() -> void:
	velocity = Vector2.ZERO

	if _voting_course_pointer == 0:
		_initiate_course()
		return
	if _voting_course_pointer == 1:
		_on_queue_reached()
		return

	_on_stop_reached()

func _initiate_course() -> void:
	_voting_course_pointer += 1
	_update_course_target()

func set_walking_course(stops: Array) -> void:
	voting_course = stops

	_update_course_target()

func _update_course_target() -> void:
	var next_stop: Node2D = null
	if _voting_course_pointer < voting_course.size():
		next_stop = _get_vote_stop(_voting_course_pointer)

	if next_stop == null:
		_is_course_finished = true
		_course_target = null

		velocity = Vector2.ZERO
		queue_free()
	else:
		_course_target = next_stop
		_find_walk_animation_name()

func _on_queue_reached() -> void:
	is_queueing = true

	if _is_shuffling:
		_is_shuffling = false
		return

	starting_spot = _get_vote_stop(1)
	voter_queued.emit()

func _on_stop_reached() -> void:
	_occupy_current_stop()

	_wait_frame_coord = _find_wait_animation_frame_coord()
	if get_tree().current_scene.stop_sounds:
		play_stop_sound()
	update_hud_frames()

	if _voting_course_pointer in Configs.VotingCourse:
		is_stopping = true
		var stop_node: Node2D = _get_vote_stop(_voting_course_pointer)
		if stop_node:
			voter_stopped.emit(stop_node.name)
	else:
		if not _wait_frame_coord.is_empty():
			_apply_wait_texture()
		_free_current_stop()
		_initiate_course()

func release_from_queue() -> bool:
	if not _is_waiting_stop_free(4):
		return false
	var stop: Node2D = _get_vote_stop(4)
	if stop and stop.has_method("occupy"):
		stop.occupy(self)
	is_queueing = false
	starting_spot = null
	_voting_course_pointer += 1
	_update_course_target()
	return true
#todo: cleanup

func continue_course() -> bool:
	if not is_stopping:
		return false
	var next_waiting: int = _find_next_vote_stop()
	if next_waiting != -1 and not _is_waiting_stop_free(next_waiting):
		return false
	if next_waiting != -1:
		var stop: Node2D = _get_vote_stop(next_waiting)
		if stop and stop.has_method("occupy"):
			stop.occupy(self)
	_free_current_stop()
	is_stopping = false
	_voting_course_pointer += 1
	_update_course_target()
	return true
#todo: cleanup

func _get_vote_stop(index: int) -> Node2D:
	if index >= 0 and index < voting_course.size():
		return voting_course[index]
	return null

func _find_next_vote_stop() -> int:
	var vote_stops: Array = Configs.VotingCourse
	for index in vote_stops:
		if index > _voting_course_pointer:
			return index
	return -1

func _is_waiting_stop_free(index: int) -> bool:
	if index >= voting_course.size():
		return true
	var stop: Node2D = _get_vote_stop(index)
	if stop == null:
		return true
	if stop.has_method("is_free"):
		return stop.is_free()
	return true
#todo: cleanup

func _is_next_stop_free() -> bool:
	var next_index: int = _voting_course_pointer + 1
	if next_index >= voting_course.size():
		return true
	var next_stop: Node2D = _get_vote_stop(next_index)
	if next_stop == null:
		return true
	if next_stop.has_method("is_free"):
		return next_stop.is_free()
	return true
#todo: cleanup

func _occupy_current_stop() -> void:
	var stop: Node2D = _get_vote_stop(_voting_course_pointer)
	if stop and stop.has_method("occupy"):
		stop.occupy(self)
#todo: cleanup

func _free_current_stop() -> void:
	var stop: Node2D = _get_vote_stop(_voting_course_pointer)
	if stop and stop.has_method("free_up"):
		stop.free_up()
#todo: cleanup

func move_to_queue_spot(target_spot: Node2D) -> void:
	starting_spot = target_spot
	_course_target = target_spot
	voting_course[1] = target_spot

	is_queueing = false
	_is_shuffling = true
	_walk_texture_restoring()
#todo: cleanup

func _set_idle_texture(direction_name: String) -> void:
	animation_player.stop()
	_initial_texture = character_texture.texture
	var idle_texture_path: String = Globals.VoterFactory[voter_factory_index]["Texture2D"]
	character_texture.texture = load(idle_texture_path)
	character_texture.hframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Hframes"]
	character_texture.vframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Vframes"]
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]["Animations"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == direction_name:
			character_texture.frame_coords = Vector2i(animation_setup[animation_view]["Frame Coord"]["x"], animation_setup[animation_view]["Frame Coord"]["y"])
			return
#todo: cleanup

func _apply_wait_texture() -> void:
	animation_player.stop()
	_initial_texture = character_texture.texture
	var idle_texture_path: String = Globals.VoterFactory[voter_factory_index]["Texture2D"]
	character_texture.texture = load(idle_texture_path)
	character_texture.hframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Hframes"]
	character_texture.vframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Vframes"]
	character_texture.frame_coords = Vector2i(_wait_frame_coord["x"], _wait_frame_coord["y"])
#todo: cleanup

func _walk_texture_restoring() -> void:
	if _initial_texture:
		character_texture.texture = _initial_texture
		character_texture.hframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Hframes"]
		character_texture.vframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Vframes"]

#plays voting stop sound
func play_stop_sound() -> void:
	var sound_stream: AudioStream = _get_stop_sound(_voting_course_pointer)

	if sound_stream:
		vote_stop_sound.volume_db = 16.0
		#todo: delete sound volume update
		if _voting_course_pointer == 7 or _voting_course_pointer == 13:
			vote_stop_sound.volume_db = 20.0

		vote_stop_sound.stream = sound_stream
		vote_stop_sound.play()

func _get_stop_sound(index: int) -> AudioStream:
	var stop_node: Node2D = _get_vote_stop(index)
	if stop_node and (stop_node.stop_sound or stop_node.cool_sound):
		return stop_node.stop_sound if not get_tree().current_scene.cool_game else stop_node.cool_sound
	return null

func update_hud_frames() -> void:
	if hud_sprites.size() < 6:
		return
	match _voting_course_pointer:
		1: hud_sprites[0].frame = 35
		2: hud_sprites[1].frame = 35
		3: hud_sprites[2].frame = 35
		4: hud_sprites[3].frame = 35
		5: hud_sprites[4].frame = 35
		6: hud_sprites[5].frame = 35

func setup_dialog(txt: String, img_path: String, should_flip: bool, label_pos: Vector2, wait_anim: String) -> void:
	status_label.text = txt
	status_label.position = label_pos
	dialog_sprite.flip_h = should_flip

	if FileAccess.file_exists(img_path):
		dialog_sprite.texture = load(img_path)

func set_heading() -> void:
	pass
