class_name CharacterDialog
extends CharacterDialogBase

signal finished()

@onready var panel: Control = $PanelContainer
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel
@onready var background: CanvasItem = $PanelContainer/BackgroundContainer

var _requestedText: String = ""
var _unveiledText: String = ""
var _tint: Color

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

func _ready() -> void:
	_initialize_placement()

func set_tint(tint: Color) -> void:
	_tint = tint

func set_text(dialog_descriptor: DialogDescriptor) -> void:
	_requestedText = dialog_descriptor.text
	_touch_debounce_timer = TOUCH_DEBOUNCE_TIME

	if dialog_descriptor.speaker == DialogDescriptor.Speaker.RIGHT:
		background.modulate = _tint
	else:
		background.modulate = DialogColors.get_default_color()
	reset_unveil()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _touch_debounce_timer > 0:
		_touch_debounce_timer -= delta
	
	if _unveiledText == _requestedText:
		return

	_unveiledText = get_unveiled(_requestedText, delta)
	text.text = _unveiledText

func _initialize_placement():
	panel.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_window().size
	panel.position = windowSize * 0.5 - panel.size * panel.scale * 0.5

func _on_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return
	
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		# if text hasn't finished unveiling, do that, otherwise emit that the panel is done
		if _unveiledText == _requestedText:
			finished.emit()
		else:
			unveil_full_text(_requestedText)
		
		_touch_debounce_timer = TOUCH_DEBOUNCE_TIME
