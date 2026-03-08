class_name Voter
extends Character

var current_stop_index: int = 0
var current_target_stop: Node2D = null
var is_waiting: bool = false
var finished_all_stops: bool = false
var current_dir_animation: String = "idle"

@onready var sfx_player: AudioStreamPlayer = $AudioStreamPlayer

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
	if not finished_all_stops and not is_waiting and current_target_stop != null:
		move_to_sequential_stop()
	else:
		velocity = Vector2.ZERO
	
	handle_input()
	handle_movement()
	handle_animations()
	set_heading()
	move_and_slide()

func update_target_stop() -> void:
	if playground:
		current_target_stop = playground.get_stop_at_index(current_stop_index)
		if current_target_stop == null:
			finished_all_stops = true
		else:
			update_animation_name()

func update_animation_name() -> void:
	match current_stop_index:
		0:
			current_dir_animation = "bottom-right"
		1, 2, 3:
			current_dir_animation = "top-right"
		4, 5:
			current_dir_animation = "top-left"
		6, 7:
			current_dir_animation = "bottom-left"
		8:
			current_dir_animation = "top-left"
		_:
			current_dir_animation = "idle"

func handle_animations() -> void:
	if state == State.WALK:
		if animation_player.current_animation != current_dir_animation:
			animation_player.play(current_dir_animation)
	else:
		animation_player.play("idle")

func move_to_sequential_stop() -> void:
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
	
	await get_tree().create_timer(1.0).timeout
	
	current_stop_index += 1
	is_waiting = false
	update_target_stop()

func play_stop_sound() -> void:
	if stop_sounds.has(current_stop_index):
		var sound_path = stop_sounds[current_stop_index]
		if FileAccess.file_exists(sound_path):
			var stream = load(sound_path)
			sfx_player.stream = stream
			sfx_player.play()

func set_heading() -> void:
	pass
