##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master gameplay runner
#maintainer      : Zeljko
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

const TEXT_POPUP_SCENE: PackedScene = preload(
		"res://!project/build/design/scenes/overlays/popups/text_popup.tscn"
)

const GAME_SUMMARY_SCENE: PackedScene = preload(
		"res://!project/build/design/scenes/overlays/popups/game_summary.tscn"
)

const ROUND_TIMER_SCENE: PackedScene = preload(
		"res://!project/build/design/scenes/overlays/round_timer.tscn"
)

const DIALOG_SIZE: Vector2i = Vector2i(1200, 900)

@export_group("Gameplay")
#voting stop sounds play while true; false once the round timer ends
@export var stop_sounds: bool = true

#private vars
var _dialog_controller: DialogController = null
var _dialog_voter: Voter = null
var _game_descriptor: GameDescriptor = null
var _popup: TextPopup = null
var _round_timer: Timer
var _round_timer_display: RoundTimerDisplay
#stations still to guide Initiate at, each the first time the room voter stops there
var _initiate_guide_stations: Array = Configs.ClassicalControllers["initiate_guide_stations"].duplicate()
#music loop the round plays right now
var _round_music: Globals.Music = Globals.Music.Round

#onready vars
@onready var stage: Stage = $Stage
@onready var progress_flow: ProgressFlow = $"Progress Flow"
@onready var dialog_layer: CanvasLayer = $"Dialog Layer"
@onready var controls: Controls = $Controls

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	_game_descriptor = GameManager.get_game_descriptor()
	progress_flow.init(stage, _game_descriptor.get_controller_type())
	progress_flow.stop_button_pressed.connect(_on_stop_button_pressed)
	stage.dialogue_requested.connect(_open_dialogue)
	stage.room_voter_stopped.connect(_on_room_voter_stopped)

	controls.init(stage, _game_descriptor.get_controller_type())
	Signals.game_close_requested.connect(_on_game_close_requested)

	_round_timer_display = ROUND_TIMER_SCENE.instantiate() as RoundTimerDisplay
	dialog_layer.add_child(_round_timer_display)
	
	_show_start_popup()


func _show_start_popup() -> void:
	_popup = TEXT_POPUP_SCENE.instantiate() as TextPopup
	dialog_layer.add_child(_popup)
	_popup.init(_game_descriptor.get_controller_type())
	#on-screen controls stay hidden while the start popup is open, whatever the controller type
	controls.hide()
	#### tentatively commented out
	#### _popup.set_text(GameManager.get_mission_descriptor().get_mission_description())
	_popup.finished.connect(_start_popup_closed)


func _start_popup_closed() -> void:
	_popup.hide()
	_popup.queue_free()
	controls.show()
	
	stage.start_spawning()
	#the round time counts from the first voter waiting in the queue
	stage.queue_count_updated.connect(_on_first_voter_queued, CONNECT_ONE_SHOT)
	_round_music = Globals.Music.Round
	SoundManager.play_jingle(Globals.Sound.RoundStart, _round_music)

#signal Stage.queue_count_updated => the first voter stopped in the queue, the round timer starts
func _on_first_voter_queued(_count: int) -> void:
	_start_round_timer()
	controls.show_guide_border()

#signal Stage.room_voter_stopped => the first stop at a guided station pulses Initiate
func _on_room_voter_stopped(station_number: int) -> void:
	if not _initiate_guide_stations.has(station_number): return

	_initiate_guide_stations.erase(station_number)
	controls.show_initiate_guide_border()

#starts the one-shot timer that ends the run
func _start_round_timer() -> void:
	_round_timer = Timer.new()
	_round_timer.one_shot = true
	_round_timer.wait_time = Configs.Round.duration
	_round_timer.timeout.connect(_on_round_timer_timeout)
	add_child(_round_timer)
	_round_timer.start()
	_round_timer_display.set_round_timer(_round_timer)

#signal Timer.timeout => the round is over, submit the score on the leaderboard
func _on_round_timer_timeout() -> void:
	#voters still walking the course no longer play their stop sounds over the round jingle and summary
	stop_sounds = false
	var round_jingle: Globals.Sound = Globals.Sound.RoundWin if _game_descriptor.get_points() > 0 else Globals.Sound.RoundLose
	SoundManager.play_jingle(round_jingle, Globals.Music.Summary)
	_show_game_summary()
	

func _show_game_summary() -> void:
	var summary_instance: GameSummary = GAME_SUMMARY_SCENE.instantiate()
	dialog_layer.add_child(summary_instance)
	summary_instance.set_choices(_game_descriptor.get_choice_history())
	summary_instance.continue_pressed.connect(GameManager.end_run)


#signal Signals.game_close_requested => quits the application
func _on_game_close_requested() -> void:
	get_tree().quit()

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update_round_music()

#switches the music while the round runs: challenge for its last seconds and while a timed dialogue is open, the round music otherwise
func _update_round_music() -> void:
	if not _round_timer or _round_timer.is_stopped(): return

	var is_timed_dialogue_open: bool = _dialog_controller != null and _game_descriptor.are_timers_enabled()
	var fitting_music: Globals.Music = Globals.Music.Round
	if _round_timer.time_left <= Configs.Round["challenge_time"] or is_timed_dialogue_open:
		fitting_music = Globals.Music.Challenge
	if fitting_music != _round_music:
		_round_music = fitting_music
		SoundManager.play_music(_round_music)

func _on_stop_button_pressed(stop_name: String, stop_index: int) -> void:
	if _dialog_controller != null:
		return

	var voter: Voter = stage.get_stopped_voter_at_stop(stop_index)
	if voter == null:
		return

	_open_dialogue(voter, stop_name)

#opens the voter's dialog for the stop it stands at, or lets it walk on when it has none there
func _open_dialogue(voter: Voter, stop_name: String) -> void:
	if _dialog_controller != null:
		return

	var dialog_id: String = voter.get_dialog_id(stop_name)
	if not DialoguesManager.has_dialogue(dialog_id):
		voter.can_continue_voting_course()
		return

	_dialog_voter = voter
	_dialog_controller = DIALOG_CONTROLLER_SCENE.instantiate() as DialogController
	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### _dialog_controller.initialize(dialog_path, DIALOG_SIZE)
	#### commented out c770ead365403da70d39409270695334d5a4f445
	#### _dialog_controller.initialize(_game_descriptor, DialoguesManager.get_dialogue(dialog_id), DIALOG_SIZE)
	var dialog_color: Color = DialogColors.get_color(_dialog_voter.name)
	_dialog_controller.initialize(_game_descriptor, DialoguesManager.get_dialogue(dialog_id), dialog_color, DIALOG_SIZE)
	_dialog_controller.set_spotlights(controls.get_button_spotlights())
	_dialog_controller.finished.connect(_on_dialog_finished)
	_dialog_controller.choice_made.connect(_on_dialog_choice_made)
	dialog_layer.add_child(_dialog_controller)

	controls.set_dialog_open(true)
	stage.set_voter_control_enabled(false)

	var voter_personality: String = _dialog_voter.get_personality()
	if Globals.DialogueMoodSounds.has(voter_personality):
		SoundManager.play_stinger(Globals.DialogueMoodSounds[voter_personality])

func _on_dialog_finished() -> void:
	var voter: Voter = _dialog_voter
	var controller: DialogController = _dialog_controller
	_dialog_voter = null
	_dialog_controller = null

	controls.set_dialog_open(false)
	stage.set_voter_control_enabled(true)

	if controller and is_instance_valid(controller):
		controller.queue_free()
	if voter and is_instance_valid(voter) and voter.is_stopping:
		voter.can_continue_voting_course()

func _on_dialog_choice_made(dialog_text: String, choice_descriptor: DialogDescriptor.ChoiceDescriptor, answer_time: float) -> void:
	var actual_score := DialogScoreCalculator.calculate_score(choice_descriptor, answer_time)
	_game_descriptor.track_choice(dialog_text, choice_descriptor, actual_score)
	var popup: Node = POINTS_VFX_SCENE.instantiate()
	dialog_layer.add_child(popup)  # or a dedicated "VFXLayer" node
	popup.global_position = _dialog_controller.global_position + _dialog_controller.size / 2
	var points_str: String = "+%.0f" % actual_score
	var points_color: Color = Color.GREEN
	var choice_stinger: Globals.Sound = Globals.Sound.ChoiceRight
	if choice_descriptor.score < 0:
		points_str = "%.0f" % actual_score
		points_color = Color.RED
		choice_stinger = Globals.Sound.ChoiceWrong
	SoundManager.play_stinger(choice_stinger)
		
	popup.setup(points_str, points_color)
	popup.play()
