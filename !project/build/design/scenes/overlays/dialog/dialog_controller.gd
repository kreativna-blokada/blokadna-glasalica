class_name DialogController
extends Control

@onready var _dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/character_dialog.tscn")
@onready var _multi_choice_dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/multi_choice_character_dialog.tscn")
@onready var _dialog_speakers_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/dialog_speakers.tscn")

signal choice_made(dialog_text: String, choice_descriptor: DialogDescriptor.ChoiceDescriptor, answer_time: float, is_best_choice: bool)
signal finished()

var _dialog_box: CharacterDialog
var _multi_choice_dialog_box: MultiChoiceCharacterDialog
var _dialog_speakers: DialogSpeakers

var _dialog_tree: DialogTree
var _current_node: DialogTreeNode
var _dialog_size: Vector2i
var _dialog_color: Color

var _timers_enabled: bool = false
var _dialog_timer: DialogTimer = DialogTimer.new()
#counts on every answer screen, whatever the difficulty, so picks stay locked for the answer lock time
var _answer_lock_timer: DialogTimer = DialogTimer.new()
#true with classic controls, Confirm / Highlight
var _is_answered_by_controls: bool = false
#false shows the smaller pre-zoom dialogues
var _is_zoomed_dialogue: bool = true
#buttons the dim leaves uncovered, canvas centre and radius each
var _spotlights: PackedVector3Array = []
#busts of the staff member on the left and the voter on the right
var _staff_portrait: Texture2D
var _voter_portrait: Texture2D

func initialize(game_descriptor: GameDescriptor, dialog_path: Dictionary, dialog_color: Color, dialog_size: Vector2i, staff_portrait: Texture2D, voter_portrait: Texture2D) -> void:
	_staff_portrait = staff_portrait
	_voter_portrait = voter_portrait
	_is_answered_by_controls = game_descriptor.get_controller_type() == Globals.ControllerType.Classic
	_is_zoomed_dialogue = game_descriptor.is_zoomed_dialogue()

	#### dialog_path should be renamed to dialog_data
	_timers_enabled = game_descriptor.are_timers_enabled()
	_dialog_tree = DialogTree.new(dialog_path)
	_current_node = _dialog_tree.get_root()
	_dialog_size = dialog_size
	_dialog_color = dialog_color
	add_child(_dialog_timer)
	add_child(_answer_lock_timer)
	_start_timer_if_needed()

#keeps the given buttons visible through the dialog dim, called before the dialog enters the tree
func set_spotlights(button_spotlights: PackedVector3Array) -> void:
	_spotlights = button_spotlights

#restarts the answer timers when the screen shows answers
func _start_timer_if_needed() -> void:
	if _current_node.get_num_choices() == 0: return

	_answer_lock_timer.restart()
	if _timers_enabled:
		_dialog_timer.restart()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_view()
	_connect_events()
	_update_view()


func _create_view() -> void:
	_dialog_box = _dialog_box_scene.instantiate()
	_multi_choice_dialog_box = _multi_choice_dialog_box_scene.instantiate()
	_dialog_speakers = _dialog_speakers_scene.instantiate()

	add_child(_dialog_box)
	add_child(_multi_choice_dialog_box)
	add_child(_dialog_speakers)

	_dialog_box.initialize(_dialog_size, _is_zoomed_dialogue)
	_dialog_box.set_tint(_dialog_color)
	var speaker_text_colors: Array[Color] = DialogColors.draw_speaker_text_colors()
	_dialog_box.set_text_colors(speaker_text_colors[0], speaker_text_colors[1])
	_multi_choice_dialog_box.set_text_colors(speaker_text_colors[0], speaker_text_colors[1])
	_multi_choice_dialog_box.initialize(_dialog_size, _is_zoomed_dialogue)
	_multi_choice_dialog_box.show_timer_vfx(_timers_enabled)
	_multi_choice_dialog_box.set_tint(_dialog_color)
	_multi_choice_dialog_box.show_choice_highlight(_is_answered_by_controls)
	_dialog_box.set_spotlights(_spotlights)
	_multi_choice_dialog_box.set_spotlights(_spotlights)

	_dialog_speakers.initialize(_current_node.get_dialog_descriptor().speaker)
	_dialog_speakers.set_dialogue_width(_dialog_size.x)
	_dialog_speakers.set_portraits(_staff_portrait, _voter_portrait)

	var box_tint: Color = Color.WHITE if _is_zoomed_dialogue else Configs.DialogueZoom["compact_box_tint"]
	_dialog_speakers.set_name_plate_colors(DialogColors.get_default_color(), _dialog_color, box_tint)
	_dialog_speakers.set_name_colors(speaker_text_colors[0], speaker_text_colors[1])

func _connect_events() -> void:
	_dialog_box.finished.connect(_on_simple_dialog_finish)
	_multi_choice_dialog_box.finished.connect(_on_multi_choice_dialog_finish)

func _update_view() -> void:
	var view_element: CharacterDialogBase
	if _current_node.get_num_choices() > 0:
		_multi_choice_dialog_box.show()
		view_element = _multi_choice_dialog_box
		_dialog_box.hide()
	else:
		_dialog_box.show()
		view_element = _dialog_box
		_multi_choice_dialog_box.hide()

	view_element.set_text(_current_node.get_dialog_descriptor())
	_dialog_speakers.set_active_speaker(_current_node.get_dialog_descriptor().speaker)

#Confirm submits the highlighted answer or goes to the next line; Highlight highlights
func _unhandled_input(event: InputEvent) -> void:
	if not _is_answered_by_controls or _current_node == null: return

	var has_choices: bool = _current_node.get_num_choices() > 0
	if event.is_action_pressed("confirm"):
		if has_choices:
			_multi_choice_dialog_box.submit_highlighted_choice()
		else:
			_dialog_box.confirm_line()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("highlight"):
		if has_choices:
			_multi_choice_dialog_box.highlight_next_choice()
		get_viewport().set_input_as_handled()

func _finish_dialog() -> void:
	_multi_choice_dialog_box.hide()
	_dialog_box.hide()

func _advance(choice: int) -> void:
	_current_node = _current_node.get_child(choice)
	if _current_node == null:
		_finish_dialog()
		finished.emit()
	else:
		_update_view()
		_start_timer_if_needed()

func _on_simple_dialog_finish() -> void:
	_advance(0)

#ignores the pick while the answer screen is locked, otherwise reports it and moves on
func _on_multi_choice_dialog_finish(choice: int) -> void:
	if _answer_lock_timer.get_elapsed_seconds() < Configs.DialogueScore["answer_lock_time"]: return

	var dialog_descriptor := _current_node.get_dialog_descriptor()
	var best_score: int = dialog_descriptor.choices.map(func(choice_descriptor): return choice_descriptor.score).max()
	var is_best_choice: bool = dialog_descriptor.choices[choice].score == best_score
	choice_made.emit(dialog_descriptor.text, dialog_descriptor.choices[choice], _dialog_timer.get_elapsed_seconds(), is_best_choice)
	_advance(choice)
