##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master gameplay runner
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
class_name Game
extends Node

@export_group("Debugging")
@export var cool_game: bool = false
@export var stop_sounds: bool = true
@export var info_dialog: bool = true

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # replace with function body.

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
