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

#private vars
var _vote_stop_index: int = 0

var _is_walk_done: bool = false
var _walk_animation_name: String = "idle"
var _wait_frame_coord: Dictionary = {}
var _original_texture: Texture2D = null

var is_waiting: bool = false
var is_queued: bool = false

signal arrived_at_queue

#data containers
var voter_stops_sound: Dictionary = Globals.VoterStopsSound

#broadcast variables
var voting_stops: Array = []
var vote_stop_target: Node2D = null

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
	pass

func _process(_delta: float) -> void:
	if _is_walk_done or is_waiting or is_queued or vote_stop_target == null:
		velocity = Vector2.ZERO
	else:
		move_to_vote_stop()

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

func set_voting_stops(stops: Array) -> void:
	voting_stops = stops
	
	set_vote_stop_target()

func set_vote_stop_target() -> void:
	if _vote_stop_index < voting_stops.size():
		var next_stop: Node2D = voting_stops[_vote_stop_index]
		
		if next_stop == null:
			_is_walk_done = true
			vote_stop_target = null
			
			velocity = Vector2.ZERO
			queue_free()
		else:
			vote_stop_target = next_stop
			_find_walk_animation_name()
	else:
		_is_walk_done = true
		vote_stop_target = null
		
		velocity = Vector2.ZERO
		queue_free()

func _find_walk_animation_name() -> void:
	match _vote_stop_index:
		0, 1, 2: _walk_animation_name = "bottom-right"
		3: _walk_animation_name = "top-right"
		4: _walk_animation_name = "top-left"
		5, 6: _walk_animation_name = "top-right"
		7, 8: _walk_animation_name = "bottom-right"
		9, 10: _walk_animation_name = "bottom-left"
		11: _walk_animation_name = "top-left"
		12: _walk_animation_name = "top-right"
		13: _walk_animation_name = "bottom-left"
		14: _walk_animation_name = "bottom-right"
		_: _walk_animation_name = "idle"

func _find_wait_animation_frame_coord() -> Dictionary:
	var animation_name: String
	match _vote_stop_index:
		0: animation_name = "bottom-right"
		4, 5, 6: animation_name = "top-left"
		7: animation_name = "top-right"
		9, 12: animation_name = "top-left"
		_: return {}
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == animation_name:
			return animation_setup[animation_view]["Frame Coord"]
	return {}

func handle_animations() -> void:
	if _is_walk_done:
		animation_player.play("bottom-right")
	elif is_waiting or is_queued:
		pass
	elif state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		animation_player.play("bottom-right")

func move_to_vote_stop() -> void:
	if vote_stop_target == null: return
	
	var sprite_height: float = character_sprite.get_rect().size.y * character_sprite.scale.y
	var feet_position: Vector2 = global_position + Vector2(0, sprite_height / 2.0)
	
	var target_pos: Vector2 = vote_stop_target.global_position
	var dist: float = feet_position.distance_to(target_pos)
	
	if dist < 5.0:
		reach_stop()
	else:
		var direction: Vector2 = (target_pos - feet_position).normalized()
		velocity = direction * speed

func reach_stop() -> void:
	velocity = Vector2.ZERO

	if _vote_stop_index == 1:
		is_queued = true
		_apply_wait_texture_for_direction("bottom-right")
		arrived_at_queue.emit()
		return

	_wait_frame_coord = _find_wait_animation_frame_coord()
	if not _wait_frame_coord.is_empty():
		is_waiting = true
		_apply_wait_texture()
		play_stop_sound()
		update_hud_frames()
		await get_tree().create_timer(1.0).timeout
		_restore_walk_texture()
		is_waiting = false

	_vote_stop_index += 1
	set_vote_stop_target()

func release_from_queue() -> void:
	_restore_walk_texture()
	is_queued = false
	_vote_stop_index += 1
	set_vote_stop_target()

func _apply_wait_texture_for_direction(direction_name: String) -> void:
	animation_player.stop()
	_original_texture = character_sprite.texture
	var idle_texture_path: String = Globals.VoterIdleAnimations["Texture2D"]
	character_sprite.texture = load(idle_texture_path)
	character_sprite.hframes = 39
	character_sprite.vframes = 5
	var animation_setup: Dictionary = Globals.VoterIdleAnimations["Animation"]
	for animation_view in animation_setup:
		if animation_setup[animation_view]["Name"] == direction_name:
			character_sprite.frame_coords = Vector2i(animation_setup[animation_view]["Frame Coord"]["x"], animation_setup[animation_view]["Frame Coord"]["y"])
			return

func _apply_wait_texture() -> void:
	animation_player.stop()
	_original_texture = character_sprite.texture
	var idle_texture_path: String = Globals.VoterIdleAnimations["Texture2D"]
	character_sprite.texture = load(idle_texture_path)
	character_sprite.hframes = 39
	character_sprite.vframes = 5
	character_sprite.frame_coords = Vector2i(_wait_frame_coord["x"], _wait_frame_coord["y"])

func _restore_walk_texture() -> void:
	if _original_texture:
		character_sprite.texture = _original_texture
		character_sprite.hframes = 39
		character_sprite.vframes = 4

func play_stop_sound() -> void:
	if voter_stops_sound.has(_vote_stop_index):
		var sound_path = voter_stops_sound[_vote_stop_index]
		
		if not sound_path.is_empty() and FileAccess.file_exists(sound_path):
			vote_stop_sound.volume_db = 0.0
			if _vote_stop_index == 11:
				vote_stop_sound.volume_db = 10.0
				
			var stream = load(sound_path)
			vote_stop_sound.stream = stream
			vote_stop_sound.play()

func update_hud_frames() -> void:
	if hud_sprites.size() < 6:
		return
	match _vote_stop_index:
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