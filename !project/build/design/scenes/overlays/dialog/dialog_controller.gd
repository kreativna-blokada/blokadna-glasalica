class_name DialogController
extends Control

@onready var _dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/character_dialog.tscn")
@onready var _multi_choice_dialog_box_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/multi_choice_character_dialog.tscn")

var _dialog_box: CharacterDialog
var _multi_choice_dialog_box: MultiChoiceCharacterDialog
var _dialog_tree: DialogTree
var _current_node: DialogTreeNode

var _dialog_size: Vector2i

func initialize(dialog_path: String, dialog_size: Vector2i) -> void:
	_dialog_tree = DialogTree.new(dialog_path)
	_current_node = _dialog_tree.get_root()
	_dialog_size = dialog_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_dialog_box = _dialog_box_scene.instantiate()
	_multi_choice_dialog_box = _multi_choice_dialog_box_scene.instantiate()
	_dialog_box.initialize(_dialog_size)
	_multi_choice_dialog_box.initialize(_dialog_size)
	add_child(_dialog_box)
	add_child(_multi_choice_dialog_box)
	_update_view()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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