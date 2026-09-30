extends Control

var _chosen_difficulty: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL

@onready var _difficulty_manager: StartDifficultyManager = $Difficulty

func _ready() -> void:
	_difficulty_manager.initialize(_chosen_difficulty)
	_difficulty_manager.difficulty_changed.connect(_on_difficulty_changed)

func _on_start_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.start_game(_chosen_difficulty, MissionDescriptor.new())


func _on_leaderboard_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.go_to_leaderboard()

func _on_difficulty_changed(difficulty: GameDescriptor.Difficulty) -> void:
	_chosen_difficulty = difficulty
