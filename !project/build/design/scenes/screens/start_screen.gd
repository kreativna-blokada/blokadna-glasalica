extends Control

var _chosen_difficulty: GameDescriptor.Difficulty = GameDescriptor.Difficulty.NORMAL

func _on_start_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.start_game(_chosen_difficulty, MissionDescriptor.new())


func _on_leaderboard_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		GameManager.go_to_leaderboard()
