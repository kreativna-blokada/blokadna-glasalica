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

#onready vars
@onready var stage: Stage = $Stage
@onready var progress_flow: CanvasLayer = $"Progress Flow"

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	# dependency injection, wiring stage w/ progress flow
	if progress_flow and progress_flow.has_method("init"):
		progress_flow.init(stage)
	if progress_flow and progress_flow.has_signal("stop_button_pressed"):
		progress_flow.connect("stop_button_pressed", Callable(self, "_on_stop_button_pressed"))
	Signals.game_close_requested.connect(_on_game_close_requested)

#signal Signals.game_close_requested => quits the application
func _on_game_close_requested() -> void:
	get_tree().quit()

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_stop_button_pressed(stop_name: String, _stop_index: int) -> void:
	stage.show_vote_stop_info(stop_name)
