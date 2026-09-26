class_name GameDescriptor

enum Difficulty {EASY, NORMAL}
	
var _difficulty: Difficulty = Difficulty.EASY
var _points: float = 0.0
var _timers_enabled: bool = false
var _choices_made: Array[DialogDescriptor.ChoiceDescriptor] = []

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
func track_choice(choice_descriptor: DialogDescriptor.ChoiceDescriptor, dampened_score: float) -> void:
	update_points(dampened_score)
	_choices_made.append(choice_descriptor)

func get_choice_history() -> Array[DialogDescriptor.ChoiceDescriptor]:
	return _choices_made