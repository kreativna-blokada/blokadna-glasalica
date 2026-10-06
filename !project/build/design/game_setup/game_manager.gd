##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Game Manager, Game Descriptor, Mission Descriptor stubs
#maintainer      : Nemanja, Zeljko
#version         : 1.1
#===============================================================================
extends Node

enum GameScreen {START, MAIN, LEADERBOARD}

var _game_descriptor: GameDescriptor = GameDescriptor.new()
var _mission_descriptor: MissionDescriptor = MissionDescriptor.new()
var _current_screen: GameScreen = GameScreen.START

func get_game_descriptor() -> GameDescriptor:
	if _current_screen == GameScreen.START:
		push_error("Tried to get game descriptor before game started")
	return _game_descriptor

func get_mission_descriptor() -> MissionDescriptor:
	return _mission_descriptor

func start_game(difficulty: GameDescriptor.Difficulty, mission_descriptor: MissionDescriptor) -> void:
	_game_descriptor = GameDescriptor.new()
	_set_difficulty(difficulty)
	_set_mission_descriptor(mission_descriptor)
	switch_screen(GameScreen.MAIN)
	
func go_to_leaderboard() -> void:
	switch_screen(GameScreen.LEADERBOARD, _current_screen == GameScreen.START)

#keeps the run score for the leaderboard screen to submit, then opens it
func end_run() -> void:
	LeaderboardManager.set_run_points(_game_descriptor.get_points())
	go_to_leaderboard()

func _set_difficulty(difficulty: GameDescriptor.Difficulty) -> void:
	_game_descriptor.set_difficulty(difficulty)

func _set_mission_descriptor(mission_descriptor: MissionDescriptor) -> void:
	_mission_descriptor = mission_descriptor

#switches to a game screen; is_switch_transient keeps the screen left for the way back
func switch_screen(game_screen: GameScreen, is_switch_transient: bool = false) -> void:
	_current_screen = game_screen
	match game_screen:
		GameScreen.START:
			#the start screen plays only its own jump sound
			SoundManager.stop_music()
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Start]["path"], is_switch_transient)
		GameScreen.MAIN:
			SoundManager.stop_music()
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Game]["path"], is_switch_transient)
		GameScreen.LEADERBOARD:
			SoundManager.play_music(Globals.Music.Summary)
			ScreenManager.switch_scene(Globals.Scenes[Globals.Scene.Leaderboard]["path"], is_switch_transient)
