class_name MultiChoiceCharacterDialog
extends CharacterDialogBase

signal finished(choice: int)

var choiceOriginal: PackedScene = preload("res://!project/build/design/scenes/overlays/dialog/view/dialog_choice.tscn")

@onready var panel_container: Control = $PanelContainer
@onready var background: Control = $PanelContainer/BackgroundContainer
@onready var text_container: Control = $PanelContainer/TextContainer
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel
@onready var timer_vfx: DialogTimerVfx = $DialogTimerVfx

var _choices: Array[DialogChoice] = []
var _requestedText: String = ""
var _unveiledText: String = ""
var _tint: Color

const MAX_NUM_CHOICES: int = 3
@export var _choiceHeight: int = 120

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

const choiceMargin: Vector2 = Vector2(24,8)

func set_tint(tint: Color) -> void:
	_tint = tint

func show_timer_vfx(show: bool) -> void:
	if show:
		timer_vfx.show()
	else:
		timer_vfx.hide()

func set_text(dialog_descriptor: DialogDescriptor) -> void:
	_initialize_choices(dialog_descriptor.choices)
	_requestedText = dialog_descriptor.text

	if dialog_descriptor.speaker == DialogDescriptor.Speaker.RIGHT:
		background.modulate = _tint
	else:
		background.modulate = DialogColors.get_default_color()

	reset_unveil()
	_touch_debounce_timer = TOUCH_DEBOUNCE_TIME

	# full text is laid out once so words never jump lines while unveiling
	_unveiledText = ""
	text.text = _requestedText
	text.visible_characters = 0

func _initialize_choices(choices: Array[DialogDescriptor.ChoiceDescriptor]) -> void:
	var numChoices: int = len(choices)
	
	for i in range(numChoices):
		_choices[i].set_text(choices[i].text)
		_choices[i].show()
	
	# hide whatever other choices are left
	for i in range(numChoices, MAX_NUM_CHOICES):
		_choices[i].hide()

	_initialize_placement(numChoices)
	timer_vfx.start_anim()

func _initialize_placement(num_choices: int) -> void:
	panel_container.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_viewport().get_visible_rect().size
	panel_container.position = windowSize * 0.5 - panel_container.size * panel_container.scale * 0.5
	
	var total_offset: float = 0
	for i in range(num_choices):
		# force height to be a single line, at the final width so the line count matches
		#### _choices[i].size = Vector2(textboxScalePx.x, _choiceHeight)
		_choices[i].size = Vector2(textboxScalePx.x - choiceMargin.x * 2, _choiceHeight)

	# frame wait is needed for the text to actually process itself :/
	await get_tree().process_frame
	
	# now, with the assumed height, calculate num lines
	# extremely finicky but ok...
	for i in range(num_choices):
		total_offset += _choiceHeight * _choices[i].get_num_lines()
	
	var accum_offset: float = 0
	for i in range(num_choices):
		_choices[i].position = panel_container.position + Vector2(0, textboxScalePx.y - textMargin.y - total_offset + accum_offset)
		_choices[i].size = Vector2(textboxScalePx.x, _choiceHeight * _choices[i].get_num_lines())
		accum_offset += _choices[i].size.y
		apply_margins(_choices[i], choiceMargin)

	# Scale the main textbox down to accomodate choices
	text_container.position = Vector2(0,0)
	#### text_container.size = panel_container.size - Vector2(0, _choiceHeight * num_choices)
	text_container.size = panel_container.size - Vector2(0, total_offset)
	apply_margins(text_container, textMargin)
	warn_if_text_overflows(text)

	# place timer to the right of the dialog box
	timer_vfx.position = panel_container.position + Vector2(panel_container.size.x + 24, 0)

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
	#### text.text = _unveiledText
	text.visible_characters = _unveiledText.length()


func _on_text_container_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return
	
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		unveil_full_text(_requestedText)
