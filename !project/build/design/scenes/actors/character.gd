class_name Character
extends CharacterBody2D

@export_group("Movement")
@export var speed : float

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

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animations()
	set_heading()
	move_and_slide()

	animation_player.play(anim_map[State.IDLE])

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

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

#sets heading based on input
func set_heading() -> void:
	pass

#flips sprite based on heading
func flip_sprites() -> void:
	if heading == Vector2.RIGHT:
		character_texture.flip_h = false

#used for movement and animation handling
func can_move() -> bool:
	return state == State.IDLE or state == State.WALK
