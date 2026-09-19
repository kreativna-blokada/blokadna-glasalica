class_name MultiChoiceCharacterDialog
extends CharacterDialogBase

signal finished(choice: int)

var choiceOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/dialog_choice.tscn")

@onready var background: Control = $PanelContainer
@onready var text_container: Control = $PanelContainer/TextContainer
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel

var _choices: Array[DialogChoice] = []
var _requestedText: String = ""
var _unveiledText: String = ""

const MAX_NUM_CHOICES: int = 3
@export var _choiceHeight: int = 100

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

const choiceMargin: Vector2 = Vector2(24,8)

func set_text(dialog_descriptor: DialogDescriptor) -> void:
	_initialize_choices(dialog_descriptor.choices)
	_requestedText = dialog_descriptor.text
	reset_unveil()
	_touch_debounce_timer = TOUCH_DEBOUNCE_TIME

func _initialize_choices(choices: Array[DialogDescriptor.ChoiceDescriptor]) -> void:
	var numChoices: int = len(choices)
	
	for i in range(numChoices):
		_choices[i].set_text(choices[i].text)
		_choices[i].show()
	
	# hide whatever other choices are left
	for i in range(numChoices, MAX_NUM_CHOICES):
		_choices[i].hide()

	_initialize_placement(numChoices)

func _initialize_placement(num_choices: int) -> void:
	background.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_window().size
	background.position = windowSize * 0.5 - background.size * background.scale * 0.5
	# Scale the main textbox down to accomodate choices
	text_container.position = Vector2(0,0)
	text_container.size = background.size - Vector2(0, _choiceHeight * num_choices)

	for i in range(num_choices):
		_choices[i].position = background.position + Vector2(0, textboxScalePx.y - textMargin.y - (num_choices - i) * _choiceHeight)
		_choices[i].size = Vector2(textboxScalePx.x, _choiceHeight)
		apply_margins(_choices[i], choiceMargin)

	apply_margins(text_container, textMargin)

func _ready() -> void:
	# pre-allocate the choices and hide them, to avoid dynamic instantiation
	for i in range(MAX_NUM_CHOICES):
		var choiceInstance: DialogChoice = choiceOriginal.instantiate();
		choiceInstance.hide()
		choiceInstance.choice_clicked.connect(_on_choice_clicked)
		_choices.append(choiceInstance)
		add_child(choiceInstance)

func _on_choice_clicked(sender: DialogChoice) -> void:
	if _unveiledText == _requestedText:
		var i: int = 0
		for choice in _choices:
			if sender == choice:
				finished.emit(i)
			i += 1
	else:
		unveil_full_text(_requestedText)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _touch_debounce_timer > 0:
		_touch_debounce_timer -= delta
	
	if _unveiledText == _requestedText:
		return

	_unveiledText = get_unveiled(_requestedText, delta)
	text.text = _unveiledText


func _on_text_container_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return
	
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		unveil_full_text(_requestedText)
