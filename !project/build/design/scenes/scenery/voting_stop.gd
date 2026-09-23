##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Voting stop placeholder
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name VotingStop
extends Node2D

#signals
signal occupancy_updated

#broadcast vars
var occupant : Character = null

@export var is_stop : bool
@export_group("Gameplay Sounds")
@export var stop_sound : AudioStream
@export var sound_volume : float
@export_group("Stop Animations")
@export var walk_animation: StopAnim = StopAnim.NONE
@export var wait_animation: StopAnim = StopAnim.NONE
enum StopAnim {
	NONE,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

#private vars
var _voting_course_group: String = "voting_course"

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	if is_stop:
		add_to_group(_voting_course_group)

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

func is_free() -> bool:
	return occupant == null

func free_up() -> void:
	occupant = null
	occupancy_updated.emit()

func occupy(character: Character) -> void:
	occupant = character
	occupancy_updated.emit()

#gets animation name from animation enum
func get_wait_animation_name() -> String:
	return _get_stop_animation_name(wait_animation)

#gets animation name from animation enum
func get_walk_animation_name() -> String:
	return _get_stop_animation_name(walk_animation)

#converts stop animation enum value to animation name string
func _get_stop_animation_name(animation_name_enum: int) -> String:
	var nimation_name_key = StopAnim.keys()[animation_name_enum]
	return nimation_name_key.to_lower().replace("_", "-")
