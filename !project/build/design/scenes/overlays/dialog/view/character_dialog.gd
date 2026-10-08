class_name CharacterDialog
extends CharacterDialogBase

signal finished()

@onready var panel: Control = $PanelContainer
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel
@onready var background: CanvasItem = $PanelContainer/BackgroundContainer
@onready var box_background: NinePatchRect = $PanelContainer/BackgroundContainer/Background
@onready var continue_hint: RichTextLabel = $PanelContainer/TextContainer/ContinueHint

var _requestedText: String = ""
var _unveiledText: String = ""
var _tint: Color
#text colours of the left and right speakers
var _left_text_color: Color
var _right_text_color: Color

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

func _ready() -> void:
	_initialize_placement()
	get_viewport().size_changed.connect(_initialize_placement)

#### usage of pre-zoom font, tint and text area re-uses 153f7a2 - 60e239c
func initialize(textboxScale: Vector2i, is_zoomed_dialogue: bool) -> void:
	super.initialize(textboxScale, is_zoomed_dialogue)
	if is_zoomed_dialogue: return

	apply_compact_look(text, box_background)
	text.offset_right = Configs.DialogueZoom["compact_text_overhang"]
	text.offset_bottom = Configs.DialogueZoom["compact_text_overhang"]

func set_tint(tint: Color) -> void:
	_tint = tint

#deep text colours the left and right speakers talk in for this dialogue
func set_text_colors(left_text_color: Color, right_text_color: Color) -> void:
	_left_text_color = left_text_color
	_right_text_color = right_text_color

func set_text(dialog_descriptor: DialogDescriptor) -> void:
	_requestedText = dialog_descriptor.text
	_touch_debounce_timer = TOUCH_DEBOUNCE_TIME

	#### commented out c770ead365403da70d39409270695334d5a4f445
	#### background.modulate = DialogColors.get_default_color()
	if dialog_descriptor.speaker == DialogDescriptor.Speaker.RIGHT:
		background.modulate = _tint
	else:
		background.modulate = DialogColors.get_default_color()
	var line_text_color: Color = _right_text_color if dialog_descriptor.speaker == DialogDescriptor.Speaker.RIGHT else _left_text_color
	DialogColors.apply_text_colors(text, line_text_color, background.modulate * box_background.modulate)
	reset_unveil()

	# full text is laid out once so words never jump lines while unveiling
	_unveiledText = ""
	text.text = _requestedText
	text.visible_characters = 0
	# only shown once the text is complete, which is when a click moves on
	continue_hint.hide()
	warn_if_text_overflows(text)

	#### pre-zoom typing grows the text from an empty label, re-using 153f7a2 - 60e239c
	if not _is_zoomed_dialogue:
		text.text = ""
		text.visible_characters = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _touch_debounce_timer > 0:
		_touch_debounce_timer -= delta
	
	if _unveiledText == _requestedText:
		return

	_unveiledText = get_unveiled(_requestedText, delta)
	#### re-using 153f7a2 - 60e239c
	#### text.text = _unveiledText
	if _is_zoomed_dialogue:
		text.visible_characters = _unveiledText.length()
	else:
		#pre-zoom typing, words may jump to the next line while unveiling
		text.text = _unveiledText
	continue_hint.visible = _unveiledText == _requestedText

func _initialize_placement():
	panel.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_viewport().get_visible_rect().size
	panel.position = windowSize * 0.5 - panel.size * panel.scale * 0.5

func _on_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return
	
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		confirm_line()
		_touch_debounce_timer = TOUCH_DEBOUNCE_TIME

#Confirm button or tap: shows the whole line if it is still unveiling, otherwise goes to the next line
func confirm_line() -> void:
	if _unveiledText == _requestedText:
		finished.emit()
	else:
		unveil_full_text(_requestedText)
