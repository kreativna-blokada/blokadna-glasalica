##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master gameplay runner
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name Game
extends Node

const DIALOG_CONTROLLER_SCENE: PackedScene = preload(
	"res://!project/build/design/scenes/overlays/dialog/dialog_controller.tscn"
)
const DIALOG_DIRECTORY: String = "res://!project/build/design/dialogues"
const DIALOG_SIZE: Vector2i = Vector2i(800, 600)

@export_group("Debugging")
@export var stop_sounds: bool = true

#private vars
var _dialog_controller: DialogController = null
var _dialog_voter: Voter = null

#onready vars
@onready var stage: Stage = $Stage
@onready var progress_flow: CanvasLayer = $"Progress Flow"
@onready var dialog_layer: CanvasLayer = $"Dialog Layer"
@onready var controls: CanvasLayer = $Controls

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	# dependency injection, wiring stage w/ progress flow
	if progress_flow and progress_flow.has_method("init"):
		progress_flow.init(stage)
	if progress_flow and progress_flow.has_signal("stop_button_pressed"):
		progress_flow.connect("stop_button_pressed", Callable(self, "_on_stop_button_pressed"))
	if controls and controls.has_method("init"):
		controls.init(stage)
	Signals.game_close_requested.connect(_on_game_close_requested)

#signal Signals.game_close_requested => quits the application
func _on_game_close_requested() -> void:
	get_tree().quit()

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_stop_button_pressed(stop_name: String, stop_index: int) -> void:
	if _dialog_controller != null:
		return

	var voter: Voter = stage.get_stopped_voter_at_stop(stop_index)
	if voter == null:
		return

	var dialog_path: String = _get_dialog_path(stop_name)
	if not FileAccess.file_exists(dialog_path):
		voter.can_continue_voting_course()
		return

	_dialog_voter = voter
	_dialog_controller = DIALOG_CONTROLLER_SCENE.instantiate() as DialogController
	_dialog_controller.initialize(dialog_path, DIALOG_SIZE)
	_dialog_controller.finished.connect(_on_dialog_finished)
	dialog_layer.add_child(_dialog_controller)

func _get_dialog_path(stop_name: String) -> String:
	return "%s/%s_dialog_01.json" % [DIALOG_DIRECTORY, stop_name.to_snake_case()]

func _on_dialog_finished() -> void:
	var voter: Voter = _dialog_voter
	var controller: DialogController = _dialog_controller
	_dialog_voter = null
	_dialog_controller = null

	if controller and is_instance_valid(controller):
		controller.queue_free()
	if voter and is_instance_valid(voter) and voter.is_stopping:
		voter.can_continue_voting_course()
