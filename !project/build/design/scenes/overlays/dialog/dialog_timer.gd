class_name DialogTimer
extends Node

var _elapsed_seconds: float = 0
var _counting: bool = false


func start() -> void:
	_counting = true

func restart() -> void:
	_elapsed_seconds = 0
	start()

func pause() -> void:
	_counting = false

func stop() -> void:
	pause()
	_elapsed_seconds = 0

func get_elapsed_seconds() -> float:
	return _elapsed_seconds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_elapsed_seconds = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _counting:
		_elapsed_seconds += delta
