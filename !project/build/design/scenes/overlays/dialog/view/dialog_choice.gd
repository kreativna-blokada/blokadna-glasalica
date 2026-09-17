class_name DialogChoice
extends Control

@onready var _text: RichTextLabel = $ChoiceText

func set_text(text: String) -> void:
	_text.text = text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
