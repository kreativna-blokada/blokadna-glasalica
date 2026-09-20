class_name StartDifficultyManager
extends Control

const TOUCH_DEBOUNCE_TIME: float = 0.1
var _touch_debounce_timer: float = 0

@onready var _textbox: RichTextLabel = $CurrentDifficulty/RichTextLabel

signal difficulty_changed(difficulty: GameDescriptor.Difficulty)

var _current_difficulty: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL

const _difficulty_text: Dictionary = {
	GameDescriptor.Difficulty.EASY: "Želim da učim",
	GameDescriptor.Difficulty.NORMAL: "Hoću izazov",
}

func initialize(difficulty: GameDescriptor.Difficulty) -> void:
	_current_difficulty = difficulty

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _touch_debounce_timer > 0:
		_touch_debounce_timer -= delta
	pass


func _on_difficulty_button_gui_input(event: InputEvent) -> void:
	if _touch_debounce_timer > 0: return

	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_touch_debounce_timer = TOUCH_DEBOUNCE_TIME
		_switch_difficulty()


func _switch_difficulty() -> void:
	match _current_difficulty:
		GameDescriptor.Difficulty.EASY:
			_current_difficulty = GameDescriptor.Difficulty.NORMAL
		GameDescriptor.Difficulty.NORMAL:
			_current_difficulty = GameDescriptor.Difficulty.EASY

	difficulty_changed.emit(_current_difficulty)
	_textbox.text = _difficulty_text[_current_difficulty]