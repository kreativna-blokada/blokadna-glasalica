class_name CharacterDialogBase
extends Node

@export var textboxScalePx: Vector2i = Vector2(800, 600)
@export var unveilSpeed: float = 30 # per second
var _unveilTimer: float = 1.0 / unveilSpeed
var _lastUnveiledCharIndex: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

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
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
