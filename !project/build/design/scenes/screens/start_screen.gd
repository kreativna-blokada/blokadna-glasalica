extends Control


func _on_start_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		ScreenManager.switch_scene("res://!project/build/design/scenes/screens/game.tscn")


func _on_leaderboard_button_gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		ScreenManager.switch_scene("res://!project/build/design/scenes/screens/leaderboards.tscn")
