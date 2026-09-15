class_name CharacterDialog
extends Control

@export var textboxScalePx: Vector2i = Vector2(800, 600)
@export var _unveilSpeed: float = 30 # per second
@onready var background: Control = $PanelContainer/BackgroundContainer/Background
@onready var text: RichTextLabel = $PanelContainer/TextContainer/RichTextLabel

var _requestedText: String = ""
var _lastUnveiledCharIndex: int = 0
var _unveilTimer: float = 1.0 / _unveilSpeed

# 16 pixel padding for the actual borders of the dialog box
# and then some :D
const textMargin: Vector2 = Vector2(24, 24)


func initialize(textboxScale: Vector2i) -> void:
	textboxScalePx = textboxScale

func _ready() -> void:
	_initialize_placement()

func set_text(text_str: String) -> void:
	_requestedText = text_str
	_lastUnveiledCharIndex = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _requestedText.length() == 0:
		return
	
	text.text = _requestedText.substr(0, _lastUnveiledCharIndex)

	_unveilTimer -= delta
	if _unveilTimer <= 0:
		_unveilTimer = 1 / _unveilSpeed
		_lastUnveiledCharIndex += 1
		if _lastUnveiledCharIndex > _requestedText.length():
			_lastUnveiledCharIndex = 0
			_requestedText = ""

func _initialize_placement():
	# Background is scaled up 8x to properly fit pixel art
	background.size = textboxScalePx * 0.125
	text.size = textboxScalePx
	# Top-left-anchored position, move by half of scale back from center of screen
	var windowSize: Vector2i = get_window().size
	background.position = windowSize * 0.5 - background.size * background.scale * 0.5
	text.position = windowSize * 0.5 - text.size * text.scale * 0.5

	text.position += textMargin
	text.size -= textMargin