class_name DialogController
extends Control

@onready var _dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/character_dialog.tscn")
@onready var _multi_choice_dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/multi_choice_character_dialog.tscn")

signal choice_made(choice_descriptor: DialogDescriptor.ChoiceDescriptor, answer_time: float)
signal finished()

var _dialog_box: CharacterDialog
var _multi_choice_dialog_box: MultiChoiceCharacterDialog
var _dialog_tree: DialogTree
var _current_node: DialogTreeNode
var _dialog_size: Vector2i
var _dialog_color: Color

var _dialog_timer: DialogTimer = DialogTimer.new()

func initialize(dialog_path: Dictionary, dialog_color: Color, dialog_size: Vector2i) -> void:
	#### dialog_path should be renamed to dialog_data
	_dialog_tree = DialogTree.new(dialog_path)
	_current_node = _dialog_tree.get_root()
	_dialog_size = dialog_size
	_dialog_color = dialog_color
	add_child(_dialog_timer)
	_start_timer_if_needed()

func _start_timer_if_needed() -> void:
	if _current_node.get_num_choices() > 0:
		_dialog_timer.restart()
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_create_view()
	_connect_events()
	_update_view()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _create_view() -> void:
	_dialog_box = _dialog_box_scene.instantiate()
	_multi_choice_dialog_box = _multi_choice_dialog_box_scene.instantiate()
	add_child(_dialog_box)
	add_child(_multi_choice_dialog_box)
	
	_dialog_box.initialize(_dialog_size)
	_dialog_box.set_tint(_dialog_color)
	_multi_choice_dialog_box.initialize(_dialog_size)
	_multi_choice_dialog_box.set_tint(_dialog_color)

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
	

func _on_multi_choice_dialog_finish(choice: int) -> void:
	choice_made.emit(_current_node.get_dialog_descriptor().choices[choice], _dialog_timer.get_elapsed_seconds())
	_advance(choice)
