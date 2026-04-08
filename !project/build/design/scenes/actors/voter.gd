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
var _cached_texture: Texture2D = null
var _walk_animation_name: String = "idle"
var _wait_frame_coord: Dictionary = {}
var _voting_course_pointer: int = 0
var _course_target: Node2D = null
var _state_entered: bool = false
var _is_course_finished: bool = false
var _is_shuffling: bool = false
var _feet_offset_enhancer: int = 2
var _stop_reach_threshold: float = 5.0

#broadcast variables
var voter_factory_index: int = -1
var voting_course: Array = []
var starting_spot: VotingStop = null
var is_queueing: bool = false
var is_stopping: bool = false

#onready vars
@onready var vote_stop_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var footstep_collider: CollisionShape2D = $CollisionShape2D

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
	if is_queueing or is_stopping or _is_course_finished or _course_target == null:
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

#transitions state by course status
func handle_movement() -> void:
	var state_check := _state

	if is_queueing:
		_state = State.WAIT
	elif is_stopping:
		_state = State.STOP
	elif _is_course_finished:
		_state = State.FINISH
	else:
		if _state == State.WAIT or _state == State.STOP:
			_state = State.IDLE
			_restore_walking_texture()
		super.handle_movement()

	if _state != state_check:
		_state_entered = false

#updates animations based on state
func handle_animations() -> void:
	if _state == State.WAIT:
		if not _state_entered:
			_set_queue_voter_texture()
	elif _state == State.STOP:
		if not _state_entered:
			if not _wait_frame_coord.is_empty():
				_set_idle_voter_texture()
	elif _state == State.FINISH:
		if not _state_entered:
			animation_player.play("top-left")
	elif _state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		super.handle_animations()

	if not _state_entered:
		_state_entered = true

#finds voter queueing / waiting (static) texture
func _set_queue_voter_texture() -> void:
	_load_idle_pose(_find_idle_frame_coords("bottom-right"))

#finds idle / waiting (static) texture
func _set_idle_voter_texture() -> void:
	_load_idle_pose(_wait_frame_coord)

#stops animation and loads static texture
func _load_idle_pose(coords: Dictionary) -> void:
	if coords.is_empty(): return

	animation_player.stop()
	if _cached_texture == null:
		_cached_texture = character_texture.texture

	var idle_texture_path: String = Globals.VoterFactory[voter_factory_index]["Texture2D"]
	character_texture.texture = load(idle_texture_path)
	character_texture.hframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Hframes"]
	character_texture.vframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Vframes"]
	character_texture.frame_coords = Vector2i(coords["x"], coords["y"])

#gets idle frame coords from global (animation) config
func _find_idle_frame_coords(anim_name: String) -> Dictionary:
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]["Animations"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == anim_name:
			return animation_setup[animation_view]["Frame Coord"]
	return {}

#resolves wait frame coords based on vote stop setup
func _find_wait_animation_frame_coord() -> Dictionary:
	if not _course_target is VotingStop or _course_target.wait_animation == VotingStop.StopAnim.NONE:
		return {}
	#get booted wait_animation from voting_stop
	var direction_name: String = _course_target.get_wait_animation_name()
	return _find_idle_frame_coords(direction_name)

#finds walk animation name by target stop setup
func _find_walk_animation_name() -> void:
	if _course_target is VotingStop:
		#get booted walk_animation from voting_stop
		_walk_animation_name = _course_target.get_walk_animation_name()
		if _walk_animation_name == "none":
			_walk_animation_name = "idle"
	else:
		_walk_animation_name = "idle"

#restores texture after wait state
func _restore_walking_texture() -> void:
	if _cached_texture:
		character_texture.texture = _cached_texture
		character_texture.hframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Hframes"]
		character_texture.vframes = Globals.VoterIdleAnimations["Animation"]["Frames"]["Vframes"]
		_cached_texture = null

#handles movement to the next stop
func voter_movement() -> void:
	if _course_target == null: return

	#moving the voter towards the target, stopping when within reach threshold
	var feet_offset: Vector2 = footstep_collider.position * _feet_offset_enhancer
	var feet_position: Vector2 = global_position + feet_offset
	var target_position: Vector2 = _course_target.global_position
	var movement_distance: float = feet_position.distance_to(target_position)
	if movement_distance < _stop_reach_threshold:
		_on_stop_reach()
	else:
		var movement_direction: Vector2 = (target_position - feet_position).normalized()
		velocity = movement_direction * speed

#stops voter, dispatches handler
func _on_stop_reach() -> void:
	velocity = Vector2.ZERO

	if _voting_course_pointer == 0:
		_next_stop()
		return
	if _voting_course_pointer == 1:
		_on_queue_reached()
		return
	_on_stop_reached()

#advances to the next voting stop
func _next_stop() -> void:
	_voting_course_pointer += 1
	_update_course_target()

#initiates voting path and course progression
func set_walking_course(stops: Array) -> void:
	voting_course = stops
	_update_course_target()

#loads next stop or handles completion
func _update_course_target() -> void:
	var next_stop: VotingStop = null
	if _voting_course_pointer < voting_course.size():
		next_stop = _get_vote_stop(_voting_course_pointer)

	if next_stop == null:
		_course_target = null
		_is_course_finished = true

		velocity = Vector2.ZERO
		queue_free()
	else:
		_course_target = next_stop
		_find_walk_animation_name()

#handles queue arrival, signals queue entry
func _on_queue_reached() -> void:
	is_queueing = true

	if _is_shuffling:
		_is_shuffling = false
		return

	starting_spot = _get_vote_stop(1)
	voter_queued.emit()

#handles arrival, decides transition
func _on_stop_reached() -> void:
	if get_tree().current_scene.stop_sounds:
		play_stop_sound()

	_voter_occupies_stop(_voting_course_pointer)
	_wait_frame_coord = _find_wait_animation_frame_coord()

	var stop_node: VotingStop = _get_vote_stop(_voting_course_pointer)
	#stops are actional or transitional
	if stop_node and stop_node.is_stop:
		is_stopping = true
		#informs stop name to info dialog
		voter_stopped.emit(stop_node.name)
	else:
		if not _wait_frame_coord.is_empty():
			_set_idle_voter_texture()

		_free_current_stop()
		_next_stop()

#checks if voter can exit queue and advance to first stop
func can_leave_queue() -> bool:
	if not _is_next_stop_free():
		return false

	starting_spot = null
	is_queueing = false
	_next_stop()

	return true

#checks if voter can leave current stop and continue course
func can_continue_voting_course() -> bool:
	if not is_stopping or not _is_next_stop_free():
		return false

	is_stopping = false
	_free_current_stop()
	_next_stop()

	return true

#checks if next wait stop is free
func _is_next_stop_free() -> bool:
	var next_stop_index: int = _find_next_wait_stop_index()
	if next_stop_index != -1 and not _is_target_stop_free(next_stop_index):
		return false

	if next_stop_index != -1:
		#reserves the next wait stop
		_voter_occupies_stop(next_stop_index)
	return true

#retrieves voting stop by index (pointer)
func _get_vote_stop(index: int) -> VotingStop:
	if index >= 0 and index < voting_course.size():
		return voting_course[index]
	return null

#finds next voting stop index ahead in course
func _find_next_wait_stop_index() -> int:
	for index in range(_voting_course_pointer + 1, voting_course.size()):
		var stop = voting_course[index]
		if stop is VotingStop and stop.is_stop:
			return index
	return -1

#checks if voting stop at index is unoccupied
func _is_target_stop_free(index: int) -> bool:
	var stop: VotingStop = _get_vote_stop(index)
	if stop == null: return true #null reference safe
	return not stop.has_method("is_free") or stop.is_free()

#stop frees it's occupant
func _free_current_stop() -> void:
	var stop: VotingStop = _get_vote_stop(_voting_course_pointer)
	if stop and stop.has_method("free_up"):
		stop.free_up()

#voter occupies vote stop
func _voter_occupies_stop(pointer: int) -> void:
	var stop: VotingStop = _get_vote_stop(pointer)
	if stop and stop.has_method("occupy"):
		stop.occupy(self)

#assigns a queue target and resets state for shuffling
func assign_queue_spot(target_spot: Node2D) -> void:
	starting_spot = target_spot
	_course_target = target_spot
	voting_course[1] = target_spot

	is_queueing = false
	_is_shuffling = true
	_restore_walking_texture()

#plays voting stop sound
func play_stop_sound() -> void:
	var stop_node: VotingStop = _get_vote_stop(_voting_course_pointer)
	var sound_stream: AudioStream = _get_stop_sound(stop_node)

	if sound_stream:
		vote_stop_sound.volume_db = stop_node.sound_volume
		vote_stop_sound.stream = sound_stream
		vote_stop_sound.play()

#retrieves stop sound from occupied voting stop
func _get_stop_sound(stop_node: Node2D) -> AudioStream:
	if stop_node and (stop_node.stop_sound or stop_node.cool_sound):
		return stop_node.stop_sound if not get_tree().current_scene.cool_game else stop_node.cool_sound
	return null
