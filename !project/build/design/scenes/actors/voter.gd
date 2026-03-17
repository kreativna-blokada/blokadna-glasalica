class_name Voter
extends Character

var current_stop_index: int = 0
var current_target_stop: Node2D = null
var is_waiting: bool = false
var finished_all_stops: bool = false
var current_dir_animation: String = "idle"
var current_wait_animation: String = "bottom-right"

@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var hud_sprites: Array = $HUD.get_children()
@onready var status_label: Label = $Dialog/Label
@onready var dialog_sprite: Sprite2D = $Dialog

var stop_sounds: Dictionary = {
	0: "",
	1: "res://!project/assets/audio/round-one.mp3",
	2: "res://!project/assets/audio/round-two.mp3",
	3: "res://!project/assets/audio/round-three.mp3",
	4: "res://!project/assets/audio/round-four.mp3",
	5: "res://!project/assets/audio/round-five.mp3",
	6: "res://!project/assets/audio/choose-your-destiny.mp3",
	7: "",
	8: ""
}

var playground: Playground:
	get:
		return get_parent() as Playground

func _ready() -> void:
	await get_tree().process_frame
	update_target_stop()

func _process(delta: float) -> void:
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

func update_target_stop() -> void:
	if playground:
		var next_stop = playground.get_stop_at_index(current_stop_index)
		
		playground.status_label.visible = (current_stop_index == 3)
		
		if next_stop == null:
			finished_all_stops = true
			current_target_stop = null
			velocity = Vector2.ZERO
		else:
			current_target_stop = next_stop
			update_animation_name()
			update_dialog() 

func update_animation_name() -> void:
	match current_stop_index:
		0: current_dir_animation = "bottom-right"
		1, 2, 3: current_dir_animation = "top-right"
		4: current_dir_animation = "top-right"
		5: current_dir_animation = "top-left"
		6, 7: current_dir_animation = "bottom-left"
		8: current_dir_animation = "top-left"
		_: current_dir_animation = "idle"

func handle_animations() -> void:
	if finished_all_stops:
		animation_player.play("bottom-right")
	elif is_waiting:
		animation_player.play(current_wait_animation)
	elif state == State.WALK:
		if animation_player.current_animation != current_dir_animation:
			animation_player.play(current_dir_animation)
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
	current_stop_index += 1
	is_waiting = false
	update_target_stop()

func play_stop_sound() -> void:
	if stop_sounds.has(current_stop_index):
		var sound_path = stop_sounds[current_stop_index]
		if not sound_path.is_empty() and FileAccess.file_exists(sound_path):
			sfx_player.volume_db = 0.0
			if current_stop_index == 6:
				sfx_player.volume_db = 10.0
				
			var stream = load(sound_path)
			sfx_player.stream = stream
			sfx_player.play()

func update_hud_frames() -> void:
	if hud_sprites.size() < 6:
		return
	match current_stop_index:
		1: hud_sprites[0].frame = 35
		2: hud_sprites[1].frame = 35
		3: hud_sprites[2].frame = 35
		4: hud_sprites[3].frame = 35
		5: hud_sprites[4].frame = 35
		6: hud_sprites[5].frame = 35

func update_dialog() -> void:
	match current_stop_index:
		0: setup_dialog("MISLIM DAKLE\nNISAM izBOSNE", "res://!project/assets/art/balloon-dream.png", true, Vector2(-205, -95), "bottom-right")
		1: setup_dialog("SKENIRAM\nPRSTIC", "res://!project/assets/art/balloon-dream.png", false, Vector2(-300, -95), "bottom-right")
		2: setup_dialog("POPRSKAM\nPRSTIC", "res://!project/assets/art/balloon-dream.png", false, Vector2(-300, -95), "bottom-right")
		3: setup_dialog("NE ZNAM\nSTA SAD?", "res://!project/assets/art/balloon-dream.png", false, Vector2(-300, -95), "bottom-right")
		4: setup_dialog("PAPIRIC\nBOMBONCE ?", "res://!project/assets/art/balloon-dream.png", true, Vector2(-205, -95), "idle")
		5: setup_dialog("BABA je REKLA\n..ZA STUDENTE !", "res://!project/assets/art/balloon-dream.png", true, Vector2(-205, -95), "top-right")
		6: setup_dialog("CHOOSE YOUR\nDESTINY !", "res://!project/assets/art/balloon-dream.png", false, Vector2(-300, -95), "top-left")
		_: setup_dialog("NECU RUZU\nHOCU SLOBODU\n#nohomo", "res://!project/assets/art/balloon-talk.png", false, Vector2(-300, -150), "idle")

func setup_dialog(txt: String, img_path: String, should_flip: bool, label_pos: Vector2, wait_anim: String) -> void:
	status_label.text = txt
	status_label.position = label_pos 
	dialog_sprite.flip_h = should_flip
	current_wait_animation = wait_anim
	
	if FileAccess.file_exists(img_path):
		dialog_sprite.texture = load(img_path)

func set_heading() -> void:
	pass
