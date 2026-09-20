class_name GameDescriptor

enum Difficulty {EASY, NORMAL}
	
var _difficulty: Difficulty = Difficulty.EASY
var _points: int = 0
var _timers_enabled: bool = false

func set_difficulty(difficulty: Difficulty) -> void:
	_difficulty = difficulty
	_timers_enabled = difficulty != Difficulty.EASY

func update_points(points: int) -> void:
	_points += points