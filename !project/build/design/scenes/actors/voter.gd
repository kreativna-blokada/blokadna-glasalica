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
signal queue_place_taken

#private vars
var _initial_texture: Texture2D = null
var _walk_animation_name: String = "idle"
var _voting_course_pointer: int = 0
var _is_stopping: bool = false
var _is_queueing: bool = false
var _is_shuffling: bool = false
var _is_course_finished: bool = false

var _wait_frame_coord: Dictionary = {}

#data containers
var voter_stops_sounds: Dictionary = Globals.VoterStopsSound

#broadcast variables
var starting_spot: Node2D = null
var voting_course: Array = []
var course_target: Node2D = null
var voter_factory_index: int = -1

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
	##set_vote_stop_target()

	#separate the materials to control outlines independently
	character_texture.material = character_texture.material.duplicate()

func _process(_delta: float) -> void:
	if _is_course_finished or _is_stopping or _is_queueing or course_target == null:
		velocity = Vector2.ZERO
	else:
		voting_course_movement()

	handle_input()
	handle_movement()
	handle_animations()
	set_heading()
	move_and_slide()

	########character_texture.material.set_shader_parameter("enabled", velocity.length() > 0)

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

func set_walking_course(stops: Array) -> void:
	voting_course = stops

	set_vote_stop_target()

func set_vote_stop_target() -> void:
	if _voting_course_pointer < voting_course.size():
		var next_stop: Node2D = voting_course[_voting_course_pointer]

		if next_stop == null:
			_is_course_finished = true
			course_target = null

			velocity = Vector2.ZERO
			queue_free()
		else:
			course_target = next_stop
			_find_walk_animation_name()
	else:
		_is_course_finished = true
		course_target = null

		velocity = Vector2.ZERO
		queue_free()

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

func handle_animations() -> void:
	if _is_course_finished:
		animation_player.play("bottom-right")
	elif _is_stopping or _is_queueing:
		pass
	elif state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		animation_player.play("bottom-right")

func voting_course_movement() -> void:
	if course_target == null: return

	#todo: clean this tentative workaround for sprite height affecting distance calculation
	var sprite_height: float = character_texture.get_rect().size.y * character_texture.scale.y
	var find_feet_position: Vector2 = global_position + Vector2(0, sprite_height / 2.0)
	var target_position: Vector2 = course_target.global_position
	var distance: float = find_feet_position.distance_to(target_position)
	if distance < 5.0:
		reach_stop()
	else:
		var direction: Vector2 = (target_position - find_feet_position).normalized()
		velocity = direction * speed
		#todo: update blunt movement

func reach_stop() -> void:
	velocity = Vector2.ZERO

	if _voting_course_pointer == 1:
		if _is_shuffling:
			_is_shuffling = false
			_is_queueing = true
			velocity = Vector2.ZERO
			_apply_wait_texture_for_direction("bottom-right")
			return
		_is_queueing = true
		starting_spot = voting_course[1]
		_apply_wait_texture_for_direction("bottom-right")

		queue_place_taken.emit()
		return

	_wait_frame_coord = _find_wait_animation_frame_coord()
	if not _wait_frame_coord.is_empty():
		_is_stopping = true
		_apply_wait_texture()
		play_stop_sound()
		update_hud_frames()
		await get_tree().create_timer(1.0).timeout
		_restore_walk_texture()
		_is_stopping = false

	_voting_course_pointer += 1
	set_vote_stop_target()
#todo: cleanup

func release_from_queue() -> void:
	_restore_walk_texture()
	_is_queueing = false
	starting_spot = null
	_voting_course_pointer += 1
	set_vote_stop_target()
#todo: cleanup

func move_to_queue_spot(target_spot: Node2D) -> void:
	starting_spot = target_spot
	course_target = target_spot
	voting_course[1] = target_spot

	_is_queueing = false
	_is_shuffling = true
	_restore_walk_texture()
#todo: cleanup

func _apply_wait_texture_for_direction(direction_name: String) -> void:
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
			vote_stop_sound.volume_db = 0.0
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