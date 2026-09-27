class_name TextPopup
extends Control

@onready var text : RichTextLabel = $Container/Text

signal finished()

func set_text(_text: String) -> void:
	text.text = _text



func _on_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		finished.emit()
