##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Game Manager, Game Descriptor, Mission Descriptor stubs
#maintainer      : Nemanja, Zeljko
#version         : 1.2
#===============================================================================
extends Node

enum GameScreen {START, MAIN, NAME_ENTRY, LEADERBOARD}

var _game_descriptor: GameDescriptor = GameDescriptor.new()
var _mission_descriptor: MissionDescriptor = MissionDescriptor.new()
var _current_screen: GameScreen = GameScreen.START
#true while the start screen is opened by the help popup Home button, the ballot then rests on the leaderboard row
var _is_returning_home: bool = false

func get_game_descriptor() -> GameDescriptor:
	if _current_screen == GameScreen.START:
		push_error("Tried to get game descriptor before game started")
	return _game_descriptor

func get_mission_descriptor() -> MissionDescriptor:
	return _mission_descriptor

#true when the start screen was opened by the help popup Home button
func is_returning_home() -> bool:
	return _is_returning_home

func start_game(controller_type: Globals.ControllerType, difficulty: GameDescriptor.Difficulty, mission_descriptor: MissionDescriptor, is_zoomed_dialogue: bool) -> void:
	_game_descriptor = GameDescriptor.new()
	_is_returning_home = false
	_set_difficulty(difficulty)
	_set_controller_type(controller_type)
	_set_zoomed_dialogue(is_zoomed_dialogue)
	_set_mission_descriptor(mission_descriptor)
	switch_screen(GameScreen.MAIN)
	
func go_to_leaderboard() -> void:
	switch_screen(GameScreen.LEADERBOARD, _current_screen == GameScreen.START)

#leaves the game for the start screen, where the ballot rests on the leaderboard row
func return_home() -> void:
	_is_returning_home = true
	switch_screen(GameScreen.START)

#keeps the run score for the name step to submit, then opens it; without a database the leaderboard opens to say so,
#as does a learning run, whose score the leaderboard only shows
func end_run() -> void:
	LeaderboardManager.set_run_points(_game_descriptor.get_points())
	if LeaderboardManager.is_enabled() and _game_descriptor.is_challenge():
		switch_screen(GameScreen.NAME_ENTRY)
	else:
		go_to_leaderboard()

func _set_difficulty(difficulty: GameDescriptor.Difficulty) -> void:
	_game_descriptor.set_difficulty(difficulty)

func _set_controller_type(controller_type: Globals.ControllerType) -> void:
	_game_descriptor.set_controller_type(controller_type)

#### dialogues toggles text zoom, re-using 153f7a2 - 60e239c
func _set_zoomed_dialogue(is_zoomed_dialogue: bool) -> void:
	_game_descriptor.set_zoomed_dialogue(is_zoomed_dialogue)

func _set_mission_descriptor(mission_descriptor: MissionDescriptor) -> void:
	_mission_descriptor = mission_descriptor

#switches to a game screen; is_switch_transient keeps the screen left for the way back
func switch_screen(game_screen: GameScreen, is_switch_transient: bool = false) -> void:
	_current_screen = game_screen
	match game_screen:
		GameScreen.START:
			SoundManager.stop_music()
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Start]["path"], is_switch_transient)
		GameScreen.MAIN:
			SoundManager.stop_music()
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Game]["path"], is_switch_transient)
		GameScreen.NAME_ENTRY:
			SoundManager.play_music(Globals.Music.Summary)
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.NameEntry]["path"], is_switch_transient)
		GameScreen.LEADERBOARD:
			SoundManager.play_music(Globals.Music.Summary)
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Leaderboard]["path"], is_switch_transient)
