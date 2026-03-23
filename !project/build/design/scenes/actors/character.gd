class_name Character
extends CharacterBody2D

@export_group("Movement")
@export var speed : float

const _SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0

@onready var animation_player := $AnimationPlayer
@onready var character_texture := $CharacterSprite

var state := State.IDLE
var heading := Vector2.RIGHT

enum State {IDLE, WALK}
enum Type {PLAYER, ENEMY}

var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
}

####func _physics_process(delta: float) -> void:
####	# Add the gravity.
####	if not is_on_floor():
####		velocity += get_gravity() * delta

####	# Handle jump.
####	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
####		velocity.y = JUMP_VELOCITY

####	# Get the input direction and handle the movement/deceleration.
####	# As good practice, you should replace UI actions with custom gameplay actions.
####	var direction := Input.get_axis("ui_left", "ui_right")
####	if direction:
####		velocity.x = direction * _SPEED
####	else:
####		velocity.x = move_toward(velocity.x, 0, _SPEED)

####	move_and_slide()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animations()
	set_heading()
	move_and_slide()

	animation_player.play(anim_map[State.IDLE])

#handle player interaction
func handle_input() -> void:
	pass

func handle_animations() -> void:
	if animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])

func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK

func set_heading() -> void:
	pass

func flip_sprites() -> void:
	if heading == Vector2.RIGHT:
		character_texture.flip_h = false

func can_move() -> bool:
	return state == State.IDLE or state == State.WALK
