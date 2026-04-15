##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master gameplay runner
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name Game
extends Node

@export_group("Debugging")
@export var stop_sounds: bool = true
@export var info_dialog: bool = true
@export var cool_game: bool = false

#onready vars
@onready var stage: Stage = $Stage
@onready var progress_flow: CanvasLayer = $"Progress Flow"

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	# dependency injection, wiring stage w/ progress flow
	if progress_flow and progress_flow.has_method("init"):
		progress_flow.init(stage)

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
