class_name GameSummary
extends Control

signal continue_pressed

@onready var _items_container: VBoxContainer = $Container/ScrollContainer/VBoxContainer
@onready var _item_template: FoldableContainer = $Container/ScrollContainer/VBoxContainer/TEMPLATE
@onready var _continue_button: Control = $Container/ContinueButton

func _ready() -> void:
	_continue_button.gui_input.connect(_on_continue_button_gui_input)

func set_choices(choices: Array[GameDescriptor.TrackedChoice]) -> void:
	for child in _items_container.get_children():
		if child != _item_template:
			child.queue_free()

	for tracked_choice in choices:
		var choice := tracked_choice.choice_descriptor
		var item := _item_template.duplicate() as FoldableContainer
		item.name = "Choice"
		item.visible = true
		item.title = choice.text
		_items_container.add_child(item)

		var dialog_label := item.get_node("Content/DialogText") as RichTextLabel
		dialog_label.text = "\"%s\"" % tracked_choice.dialog_text

		var choice_label := item.get_node("Content/ChoiceText") as RichTextLabel
		choice_label.text = "Vaš izbor: %s" % choice.text

		var explanation_label := item.get_node("Content/ExplanationText") as RichTextLabel
		explanation_label.text = choice.explanation

func _on_continue_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		continue_pressed.emit()
	elif event is InputEventScreenTouch and event.pressed:
		continue_pressed.emit()
