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
signal voter_stopped(stop_name: String)

#private vars
var _initial_texture: Texture2D = null
var _walk_animation_name: String = "idle"
var _voting_course_pointer: int = 0
var _course_target: Node2D = null
var _is_course_finished: bool = false
var _is_shuffling: bool = false

var _wait_frame_coord: Dictionary = {}

#data containers
var voter_stops_sounds: Dictionary = Globals.VoterStopsSounds

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

func get_vote_stop(index: int) -> Node2D:
	if index >= 0 and index < voting_course.size():
		return voting_course[index]
	return null

func _find_walk_animation_name() -> void:
	match _voting_course_pointer:
		0, 1, 2: _walk_animation_name = "bottom-right"
		3: _walk_animation_name = "top-right"
		4: _walk_animation_name = "top-left"
		5, 6, 7: _walk_animation_name = "top-right"
		8, 9: _walk_animation_name = "bottom-right"
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
		4, 5, 6, 7: animation_name = "top-left"
		8: animation_name = "top-right"
		10, 13: animation_name = "top-left"
		_: return {}
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == animation_name:
			return animation_setup[animation_view]["Frame Coord"]
	return {}
#todo: cleanup

func handle_animations() -> void:
	if _is_course_finished:
		animation_player.play("top-left")
	elif is_stopping or is_queueing:
		pass
	elif state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		animation_player.play("bottom-right")
#todo: cleanup

func voter_movement() -> void:
	if _course_target == null: return

	#todo: clean this tentative workaround for sprite height affecting distance calculation
	var sprite_height: float = character_texture.get_rect().size.y * character_texture.scale.y
	var find_feet_position: Vector2 = global_position + Vector2(0, sprite_height / 2.0)
	var target_position: Vector2 = _course_target.global_position
	var distance: float = find_feet_position.distance_to(target_position)
	if distance < 5.0:
		_on_stop_reach()
	else:
		var direction: Vector2 = (target_position - find_feet_position).normalized()
		velocity = direction * speed
		#todo: update blunt movement

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
		next_stop = get_vote_stop(_voting_course_pointer)

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
	_set_idle_texture("bottom-right")

	if _is_shuffling:
		_is_shuffling = false
		return

	starting_spot = get_vote_stop(1)
	voter_queued.emit()

func _on_stop_reached() -> void:
	_occupy_current_stop()

	_wait_frame_coord = _find_wait_animation_frame_coord()
	if not _wait_frame_coord.is_empty():
		_apply_wait_texture()
	play_stop_sound()
	update_hud_frames()

	if _voting_course_pointer in Globals.VotingCourse:
		is_stopping = true
		var stop_node: Node2D = get_vote_stop(_voting_course_pointer)
		if stop_node:
			voter_stopped.emit(stop_node.name)
	else:
		_free_current_stop()
		_initiate_course()
#todo: cleanup

func release_from_queue() -> bool:
	if not _is_waiting_stop_free(4):
		return false
	var stop: Node2D = get_vote_stop(4)
	if stop and stop.has_method("occupy"):
		stop.occupy(self)
	_restore_walk_texture()
	is_queueing = false
	starting_spot = null
	_voting_course_pointer += 1
	_update_course_target()
	return true
#todo: cleanup

func continue_course() -> bool:
	if not is_stopping:
		return false
	var next_waiting: int = _find_next_waiting_stop()
	if next_waiting != -1 and not _is_waiting_stop_free(next_waiting):
		return false
	if next_waiting != -1:
		var stop: Node2D = get_vote_stop(next_waiting)
		if stop and stop.has_method("occupy"):
			stop.occupy(self)
	_free_current_stop()
	is_stopping = false
	_restore_walk_texture()
	_voting_course_pointer += 1
	_update_course_target()
	return true
#todo: cleanup

func _find_next_waiting_stop() -> int:
	var waiting_stops: Array = Globals.VotingCourse
	for index in waiting_stops:
		if index > _voting_course_pointer:
			return index
	return -1
#todo: cleanup

func _is_waiting_stop_free(index: int) -> bool:
	if index >= voting_course.size():
		return true
	var stop: Node2D = get_vote_stop(index)
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
	var next_stop: Node2D = get_vote_stop(next_index)
	if next_stop == null:
		return true
	if next_stop.has_method("is_free"):
		return next_stop.is_free()
	return true
#todo: cleanup

func _occupy_current_stop() -> void:
	var stop: Node2D = get_vote_stop(_voting_course_pointer)
	if stop and stop.has_method("occupy"):
		stop.occupy(self)
#todo: cleanup

func _free_current_stop() -> void:
	var stop: Node2D = get_vote_stop(_voting_course_pointer)
	if stop and stop.has_method("free_up"):
		stop.free_up()
#todo: cleanup

func move_to_queue_spot(target_spot: Node2D) -> void:
	starting_spot = target_spot
	_course_target = target_spot
	voting_course[1] = target_spot

	is_queueing = false
	_is_shuffling = true
	_restore_walk_texture()
#todo: cleanup

func _set_idle_texture(direction_name: String) -> void:
	animation_player.stop()
	_initial_texture = character_texture.texture
	var idle_texture_path: String = Globals.VoterFactory[voter_factory_index]["Texture2D"]
	character_texture.texture = load(idle_texture_path)
	character_texture.hframes = 39
	character_texture.vframes = 5
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]
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
	character_texture.hframes = 39
	character_texture.vframes = 5
	character_texture.frame_coords = Vector2i(_wait_frame_coord["x"], _wait_frame_coord["y"])
#todo: cleanup

func _restore_walk_texture() -> void:
	if _initial_texture:
		character_texture.texture = _initial_texture
		character_texture.hframes = 39
		character_texture.vframes = 5
#todo: cleanup

#plays voting stop sound
func play_stop_sound() -> void:
	if voter_stops_sounds.has(_voting_course_pointer):
		var sound_path = voter_stops_sounds[_voting_course_pointer]

		if not sound_path.is_empty() and FileAccess.file_exists(sound_path):
			vote_stop_sound.volume_db = 10.0
			#todo: delete sound volume adjustment
			if _voting_course_pointer == 11:
				vote_stop_sound.volume_db = 10.0

			var sound_stream = load(sound_path)
			vote_stop_sound.stream = sound_stream
			vote_stop_sound.play()

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
