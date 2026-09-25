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

const POINTS_VFX_SCENE: PackedScene = preload(
		"res://!project/build/design/vfx/points_vfx.tscn"
)

const DIALOG_SIZE: Vector2i = Vector2i(800, 600)

@export_group("Debugging")
@export var stop_sounds: bool = true

#private vars
var _dialog_controller: DialogController = null
var _dialog_voter: Voter = null
var _game_descriptor: GameDescriptor = null

#onready vars
@onready var stage: Stage = $Stage
@onready var progress_flow: ProgressFlow = $"Progress Flow"
@onready var dialog_layer: CanvasLayer = $"Dialog Layer"
@onready var controls: Controls = $Controls

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	progress_flow.init(stage)
	progress_flow.stop_button_pressed.connect(_on_stop_button_pressed)
	controls.init(stage)
	Signals.game_close_requested.connect(_on_game_close_requested)

	_game_descriptor = GameManager.get_game_descriptor()

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

	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### var dialog_path: String = voter.get_dialog_path(stop_name)
	#### if not FileAccess.file_exists(dialog_path):
	#### 	voter.can_continue_voting_course()
	#### 	return
	var dialog_id: String = voter.get_dialog_id(stop_name)
	if not DialoguesManager.has_dialogue(dialog_id):
		voter.can_continue_voting_course()
		return

	_dialog_voter = voter
	_dialog_controller = DIALOG_CONTROLLER_SCENE.instantiate() as DialogController
	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### _dialog_controller.initialize(dialog_path, DIALOG_SIZE)
	var dialog_color = DialogColors.get_color(_dialog_voter.name)
	_dialog_controller.initialize(_game_descriptor, DialoguesManager.get_dialogue(dialog_id), dialog_color, DIALOG_SIZE)
	_dialog_controller.finished.connect(_on_dialog_finished)
	_dialog_controller.choice_made.connect(_on_dialog_choice_made)
	dialog_layer.add_child(_dialog_controller)

func _on_dialog_finished() -> void:
	var voter: Voter = _dialog_voter
	var controller: DialogController = _dialog_controller
	_dialog_voter = null
	_dialog_controller = null

	if controller and is_instance_valid(controller):
		controller.queue_free()
	if voter and is_instance_valid(voter) and voter.is_stopping:
		voter.can_continue_voting_course()

func _on_dialog_choice_made(choice_descriptor: DialogDescriptor.ChoiceDescriptor, answer_time: float) -> void:
	_game_descriptor.track_choice(choice_descriptor)
	var actual_score := DialogScoreCalculator.calculate_score(choice_descriptor, answer_time)
	var popup: Node = POINTS_VFX_SCENE.instantiate()
	dialog_layer.add_child(popup)  # or a dedicated "VFXLayer" node
	popup.global_position = _dialog_controller.global_position + _dialog_controller.size / 2
	var points_str: String = "+%.0f" % actual_score
	var points_color: Color = Color.GREEN
	if choice_descriptor.score < 0:
		points_str = "%.0f" % actual_score
		points_color = Color.RED
		
	popup.setup(points_str, points_color)
	popup.play()
