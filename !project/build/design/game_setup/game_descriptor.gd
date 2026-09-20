class_name GameDescriptor

enum Difficulty {EASY, NORMAL}
	
var _difficulty: Difficulty = Difficulty.EASY
var _points: int = 0
var _timers_enabled: bool = false
var _choices_made: Array[DialogDescriptor.ChoiceDescriptor] = []

func set_difficulty(difficulty: Difficulty) -> void:
	_difficulty = difficulty
	_timers_enabled = difficulty != Difficulty.EASY

func update_points(points: int) -> void:
	_points += points

func track_choice(choice_descriptor: DialogDescriptor.ChoiceDescriptor) -> void:
	update_points(choice_descriptor.score)
	_choices_made.append(choice_descriptor)

func get_choice_history() -> Array[DialogDescriptor.ChoiceDescriptor]:
	return _choices_made