extends Control

var dialogBoxOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/character_dialog.tscn")
var multiChoiceDialogBoxOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/multi_choice_character_dialog.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Instantiating dialog box")
	_create_basic_dialog_box()
	# _create_multi_choice_dialog_box()

	print("Instantiating dummy tree")
	var tree: DialogTree = DialogTree.new("res://!project/build/design/scenes/overlays/dialog/resources/sample_dialog.json")
	

func _create_basic_dialog_box() -> void:
	var instance: CharacterDialog = dialogBoxOriginal.instantiate()
	instance.initialize(Vector2i(800, 600))
	instance.set_text("Hello world! Lorem ipsum dolor sit amet niška banja topla voda za nišlije živa zgoda")
	add_child(instance)

func _create_multi_choice_dialog_box() -> void:
	var instance: MultiChoiceCharacterDialog = multiChoiceDialogBoxOriginal.instantiate()
	instance.initialize(Vector2i(800, 600))
	add_child(instance)
	instance.set_text("Hello world! Lorem ipsum dolor sit amet niška banja topla voda za nišlije živa zgoda",
	["Ma je li", "Op", "Lorem ipsum dolor sit amet tralala"])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
