extends Control

var dialog_controller_scene: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/dialog_controller.tscn")

var dialog_controller: DialogController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Instantiating dialog")
	#_create_basic_dialog_box()
	# _create_multi_choice_dialog_box()
	_create_dialog_controller()

func _create_dialog_controller() -> void:
	dialog_controller = dialog_controller_scene.instantiate()
	var dialog_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://!project/build/design/scenes/overlays/dialog/resources/sample_dialog.json"))
	if not dialog_data is Dictionary:
		push_error("DialogTests._create_dialog_controller: sample_dialog.json is not valid JSON")
		return
	dialog_controller.initialize(dialog_data, Vector2i(800, 600))
	dialog_controller.choice_made.connect(_on_dialog_choice)
	dialog_controller.finished.connect(_on_dialog_finished)
	add_child(dialog_controller)

func _on_dialog_choice(choice_desc: DialogDescriptor.ChoiceDescriptor) -> void:
	print("Score changed by %d" % choice_desc.score)

func _on_dialog_finished() -> void:
	dialog_controller.queue_free()
	get_tree().create_timer(1.0).timeout.connect(_create_dialog_controller)
