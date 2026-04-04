##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Base character controller
#author          : Zeljko Vulovic
#date            : 20260210
#version         : 1.0
#===============================================================================
class_name Character
extends CharacterBody2D

@export_group("Movement")
@export var speed : float

#private vars
enum State {WALK, IDLE, WAIT, STOP, FINISH}
enum Type {PLAYER, VOTER}

var _state := State.IDLE
var _heading := Vector2.RIGHT
var _animation_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
}

#onready vars
@onready var animation_player := $AnimationPlayer
@onready var character_texture := $CharacterSprite

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
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

#handle player interaction
func handle_input() -> void:
	pass

func handle_animations() -> void:
	if animation_player.has_animation(_animation_map[_state]):
		animation_player.play(_animation_map[_state])
#todo: unused, called by without a real purpose, use

#set state based on velocity
func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			_state = State.IDLE
		else:
			_state = State.WALK

#sets heading based on input
func set_heading() -> void:
	pass

#flips sprite based on heading
func flip_sprites() -> void:
	if _heading == Vector2.RIGHT:
		character_texture.flip_h = false

#used for movement and animation handling
func can_move() -> bool:
	return _state == State.IDLE or _state == State.WALK
