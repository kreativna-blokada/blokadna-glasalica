class_name GameDescriptor

class TrackedChoice:
	var dialog_text: String
	var choice_descriptor: DialogDescriptor.ChoiceDescriptor

	func _init(_dialog_text: String, _choice_descriptor: DialogDescriptor.ChoiceDescriptor) -> void:
		dialog_text = _dialog_text
		choice_descriptor = _choice_descriptor

enum Difficulty {EASY, NORMAL}
	
var _difficulty: Difficulty = Difficulty.EASY
var _points: float = 0.0
var _timers_enabled: bool = false
var _choices_made: Array[TrackedChoice] = []

func set_difficulty(difficulty: Difficulty) -> void:
	_difficulty = difficulty
	_timers_enabled = difficulty != Difficulty.EASY

func are_timers_enabled() -> bool:
	return _timers_enabled

func update_points(points: float) -> void:
	_points += points

#returns the run score rounded to whole points
func get_points() -> int:
	return roundi(_points)

#records the choice and adds its timer-dampened score
func track_choice(dialog_text: String, choice_descriptor: DialogDescriptor.ChoiceDescriptor, dampened_score: float) -> void:
	update_points(dampened_score)
	_choices_made.append(TrackedChoice.new(dialog_text, choice_descriptor))

func get_choice_history() -> Array[TrackedChoice]:
	return _choices_made
