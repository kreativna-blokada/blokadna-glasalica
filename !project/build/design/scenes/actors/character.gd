##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Base character controller
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
class_name Character
extends CharacterBody2D

@export_group("Movement")
@export var movement_speed : float

#private vars
var _state := State.IDLE

enum State {WALK, IDLE, WAIT, STOP, FINISH}
enum Type {PLAYER, VOTER}

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
	pass

#set state based on velocity
func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			_state = State.IDLE
		else:
			_state = State.WALK

#used for movement and animation handling
func can_move() -> bool:
	return _state == State.IDLE or _state == State.WALK
