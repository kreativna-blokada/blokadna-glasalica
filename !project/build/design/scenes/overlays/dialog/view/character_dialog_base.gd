class_name CharacterDialogBase
extends Node

@export var textboxScalePx: Vector2i = Vector2(800, 600)
@export var unveilSpeed: float = 30 # per second
var _unveilTimer: float = 1.0 / unveilSpeed
var _lastUnveiledCharIndex: int = 0

# 16 pixel padding for the actual borders of the dialog box
# and then some :D
const textMargin: Vector2 = Vector2(24, 24)

func initialize(textboxScale: Vector2i) -> void:
	textboxScalePx = textboxScale

func _ready() -> void:
	pass

func reset_unveil() -> void:
	_lastUnveiledCharIndex = 0

func unveil_full_text(text: String) -> void:
	_lastUnveiledCharIndex = text.length()

func get_unveiled(text: String, delta: float) -> String:
	_unveilTimer -= delta
	if _unveilTimer <= 0:
		_unveilTimer = 1 / unveilSpeed
		_lastUnveiledCharIndex += 1
		if _lastUnveiledCharIndex > text.length():
			_lastUnveiledCharIndex = text.length()
			
	return text.substr(0, _lastUnveiledCharIndex)


func apply_margins(node: Control, margin: Vector2) -> void:
	node.position += margin
	node.size -= margin * 2
