extends Control

var dialogBoxOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/character_dialog.tscn")
var multiChoiceDialogBoxOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/multi_choice_character_dialog.tscn")
var dialog_controller_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/dialog_controller.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Instantiating dialog")
	#_create_basic_dialog_box()
	_create_multi_choice_dialog_box()
	# _create_dialog_controller()

func _create_dialog_controller() -> void:
	var instance: DialogController = dialog_controller_scene.instantiate()
	instance.initialize("res://!project/build/design/scenes/overlays/dialog/resources/sample_dialog.json", Vector2i(800, 600))
	add_child(instance)

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

	instance.finished.connect(_on_multi_choice_finished)

func _on_multi_choice_finished(choice_idx: int) -> void:
	print("Chosen %d" % choice_idx)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
