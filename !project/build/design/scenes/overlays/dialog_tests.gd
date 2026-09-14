extends Control

var dialogBoxOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/character_dialog.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Instantiating dialog box")
	var instance: CharacterDialog = dialogBoxOriginal.instantiate()
	instance.initialize(Vector2i(800, 600))
	instance.set_text("Hello world! Lorem ipsum dolor sit amet niška banja topla voda za nišlije živa zgoda")
	add_child(instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
