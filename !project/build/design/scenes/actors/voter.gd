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
var vote_stop_index: int = 0
var current_target_stop: Node2D = null
var is_waiting: bool = false
var finished_all_stops: bool = false

var _walk_animation_name: String = "idle"
var _wait_animation_name: String = "bottom-right"

#data containers
var voter_stops_sound: Dictionary = Globals.VoterStopsSound

#broadcast variables
var stage: Stage = null

#onready vars
@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer
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
	
	update_target_stop()

func _process(_delta: float) -> void:
	# If finished or waiting, force velocity to zero to prevent any sliding/returning
	if finished_all_stops or is_waiting or current_target_stop == null:
		velocity = Vector2.ZERO
	else:
		move_to_sequential_stop()

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

func update_target_stop() -> void:
	if stage:
		var next_stop = stage.get_stop_at_index(vote_stop_index)
		
		###stage.status_label.visible = (vote_stop_index == 3)
		
		if next_stop == null:
			finished_all_stops = true
			current_target_stop = null
			velocity = Vector2.ZERO
			
			queue_free()
		else:
			current_target_stop = next_stop
			
			_get_walk_animation_name()

func _get_walk_animation_name() -> void:
	match vote_stop_index:
		0, 1: _walk_animation_name = "bottom-right"
		2: _walk_animation_name = "top-right"
		3: _walk_animation_name = "top-left"
		4, 5: _walk_animation_name = "top-right"
		6, 7: _walk_animation_name = "bottom-right"
		8, 9: _walk_animation_name = "bottom-left"
		10: _walk_animation_name = "top-left"
		11: _walk_animation_name = "top-right"
		12: _walk_animation_name = "bottom-left"
		13: _walk_animation_name = "bottom-right"
		_: _walk_animation_name = "idle"

func handle_animations() -> void:
	if finished_all_stops:
		animation_player.play("bottom-right")
	elif is_waiting:
		animation_player.play(_wait_animation_name)
	elif state == State.WALK:
		if animation_player.current_animation != _walk_animation_name:
			animation_player.play(_walk_animation_name)
	else:
		animation_player.play("bottom-right")

func move_to_sequential_stop() -> void:
	if current_target_stop == null: return
	
	var sprite_height = character_sprite.get_rect().size.y * character_sprite.scale.y
	var feet_position = global_position + Vector2(0, sprite_height / 2.0)
	
	var target_pos = current_target_stop.global_position
	var dist = feet_position.distance_to(target_pos)
	
	if dist < 5.0:
		reach_stop()
	else:
		var direction = (target_pos - feet_position).normalized()
		velocity = direction * speed

func reach_stop() -> void:
	velocity = Vector2.ZERO
	is_waiting = true
	
	play_stop_sound()
	update_hud_frames()
	
	await get_tree().create_timer(1.0).timeout
	
	# Only proceed if we aren't at the very last possible index
	vote_stop_index += 1
	is_waiting = false
	update_target_stop()

func play_stop_sound() -> void:
	if voter_stops_sound.has(vote_stop_index):
		var sound_path = voter_stops_sound[vote_stop_index]
		if not sound_path.is_empty() and FileAccess.file_exists(sound_path):
			sfx_player.volume_db = 0.0
			if vote_stop_index == 11:
				sfx_player.volume_db = 10.0
				
			var stream = load(sound_path)
			sfx_player.stream = stream
			sfx_player.play()

func update_hud_frames() -> void:
	if hud_sprites.size() < 6:
		return
	match vote_stop_index:
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
	_wait_animation_name = wait_anim
	
	if FileAccess.file_exists(img_path):
		dialog_sprite.texture = load(img_path)

func set_heading() -> void:
	pass
