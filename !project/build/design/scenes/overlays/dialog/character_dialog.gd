class_name CharacterDialog
extends CharacterDialogBase

@onready var background: Control = $PanelContainer/BackgroundContainer/Background
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel

var _requestedText: String = ""
var _unveiledText: String = ""

func _ready() -> void:
	_initialize_placement()

func set_text(text_str: String) -> void:
	_requestedText = text_str
	reset_unveil()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _unveiledText == _requestedText:
		return

	_unveiledText = get_unveiled(_requestedText, delta)
	text.text = _unveiledText

func _initialize_placement():
	# Background is scaled up 8x to properly fit pixel art
	background.size = textboxScalePx * 0.125
	text.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_window().size
	background.position = windowSize * 0.5 - background.size * background.scale * 0.5
	text.position = windowSize * 0.5 - text.size * text.scale * 0.5

	apply_margins(text, textMargin)

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		unveil_full_text(_requestedText)
