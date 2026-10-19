##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Global configurations loader
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
extends Node


const PATH: String = "res://!project/build/config/globals.gd"
#gitignored, bundled into exports through the preset include filter
const RUNTIME_CREDENTIALS: String = "res://runtime_credentials.cfg"

enum Scene {
	Start,
	Game,
	Voter,
	Info,
	Playround,
	Leaderboard,
	NameEntry
}

var Scenes: Dictionary[Variant, Variant] = {
	Scene.Start: {
		"path": "res://!project/build/design/scenes/screens/start_screen.tscn"
	},
	Scene.Game: {
		"path": "res://!project/build/design/scenes/screens/game.tscn"
	},
	Scene.Voter: {
		"path": "res://!project/build/design/scenes/actors/voter.tscn",
		"structure": {
			"sprite": "CharacterSprite",
			"shape": "CollisionShape2D",
			"animation": "AnimationPlayer",
			"audio": "AudioStreamPlayer",
		}
	},
	Scene.Info: {
		"path": "res://!project/build/design/scenes/overlays/info.tscn"
	},
	Scene.Playround: {
		"path": "res://!project/build/design/scenes/playground.tscn"
	},
	Scene.Leaderboard: {
		"path": "res://!project/build/design/scenes/screens/leaderboard/leaderboard.tscn"
	},
	Scene.NameEntry: {
		"path": "res://!project/build/design/scenes/screens/leaderboard/name_entry.tscn"
	}
}

#controls picked on the main menu controls row
enum ControllerType {
	Classic,
	Screen
}

#main menu options
enum MainMenu {
	Leaderboard,
	Difficulty,
	Starting,
	Controls,
	Team
}

#GAMEPLAY
# ██████╗  █████╗ ███╗   ███╗███████╗██████╗ ██╗      █████╗ ██╗   ██╗
#██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝
#██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝██║     ███████║ ╚████╔╝
#██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔═══╝ ██║     ██╔══██║  ╚██╔╝
#╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║     ███████╗██║  ██║   ██║
# ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝

#mood markings at the start of dialogue text, hidden from the player
const DIALOGUE_MOOD_MARKERS: Array[String] = ["[POL]", "[ANG]"]

enum Direction {
	TopLeft,
	TopRight,
	BottomLeft,
	BottomRight,
}

#music loops, one plays at a time; the start screen has none, its jump sound plays there
enum Music {
	Round,
	Challenge,
	Summary
}

var MusicLoops: Dictionary[Variant, Variant] = {
	#95 bpm, builds slowly over the 5 minute round
	Music.Round: "res://!project/audio/music/round_loop.ogg",
	#130 bpm, for timed dialogues and the last seconds of the round
	Music.Challenge: "res://!project/audio/music/challenge_loop.ogg",
	Music.Summary: "res://!project/audio/music/summary_loop.ogg",
}

#one-shot jingles and stingers; the polling station steps play their own sounds, set on each voting stop
enum Sound {
	RoundStart,
	RoundWin,
	RoundLose,
	ChoiceRight,
	ChoiceWrong,
	Points,
	MenuSelect,
	DialoguePolite,
	DialogueHostile
}

var SoundClips: Dictionary[Variant, Variant] = {
	Sound.RoundStart: "res://!project/audio/jingles/game_start.ogg",
	Sound.RoundWin: "res://!project/audio/jingles/round_win.ogg",
	Sound.RoundLose: "res://!project/audio/jingles/round_lose.ogg",
	Sound.ChoiceRight: "res://!project/audio/stingers/choice_right.ogg",
	Sound.ChoiceWrong: "res://!project/audio/stingers/choice_wrong.ogg",
	Sound.Points: "res://!project/audio/stingers/points.ogg",
	Sound.MenuSelect: "res://!project/audio/stingers/ui_select.ogg",
	Sound.DialoguePolite: "res://!project/audio/stingers/dialogue_polite.ogg",
	Sound.DialogueHostile: "res://!project/audio/stingers/dialogue_hostile.ogg",
}

#stinger opening a dialogue, by the voter personality from the dialogue file names
var DialogueMoodSounds: Dictionary[String, Variant] = {
	"polite": Sound.DialoguePolite,
	"angry": Sound.DialogueHostile,
}

#outcome of a leaderboard score submission
enum ScoreSubmit {
	Accepted,
	Stored,
	Failed
}

#leaderboard tab picking showing scores
enum ScoreBoard {
	Daily,
	Weekly,
	Total
}

#why the database did not give the player the username
enum NameRefuse {
	Taken,
	Failed
}

#ENTITY
#███████╗███╗   ██╗████████╗██╗████████╗██╗   ██╗
#██╔════╝████╗  ██║╚══██╔══╝██║╚══██╔══╝╚██╗ ██╔╝
#█████╗  ██╔██╗ ██║   ██║   ██║   ██║    ╚████╔╝
#██╔══╝  ██║╚██╗██║   ██║   ██║   ██║     ╚██╔╝
#███████╗██║ ╚████║   ██║   ██║   ██║      ██║
#╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝   ╚═╝      ╚═╝

enum Entity {
	Voter
}

var EntityProperties: Dictionary[Variant, Variant] = {
	Entity.Voter: {
		"scene":	Scenes[Scene.Voter]["path"],
		"group":	"voter",
	},
}

#VOTER
#██╗   ██╗ ██████╗ ████████╗███████╗██████╗
#██║   ██║██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗
#██║   ██║██║   ██║   ██║   █████╗  ██████╔╝
#╚██╗ ██╔╝██║   ██║   ██║   ██╔══╝  ██╔══██╗
# ╚████╔╝ ╚██████╔╝   ██║   ███████╗██║  ██║
#  ╚═══╝   ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝

enum Voter {
	MaleCap,
	MaleBlack,
	MaleBlue,
	MaleGreen,
	MaleIndigo,
	MaleMagenta,
	MaleRed,
	MaleViolet,
	MaleYellow,
	FemaleBlondeLilacSkirt,
	FemaleBlondeRoseSkirt,
	FemaleBlondeWineSkirt,
	FemaleBrunetteLilacSkirt,
	FemaleBrunetteRoseSkirt,
	FemaleBrunetteWineSkirt,
	FemaleShortHairBlondeLilacPants,
	FemaleShortHairBrunetteRosePants
}

var VoterFactory: Dictionary[Variant, Variant] = {
	Voter.MaleCap: {
		"Texture2D": "res://!project/art/male-cap.png",
		"Portrait": Vector2i(0, 0),
	},
	Voter.MaleBlue: {
		"Texture2D": "res://!project/art/male-blue.png",
		"Portrait": Vector2i(1, 0),
	},
	Voter.MaleGreen: {
		"Texture2D": "res://!project/art/male-green.png",
		"Portrait": Vector2i(2, 0),
	},
	Voter.MaleIndigo: {
		"Texture2D": "res://!project/art/male-indigo.png",
		"Portrait": Vector2i(3, 0),
	},
	Voter.MaleMagenta: {
		"Texture2D": "res://!project/art/male-magenta.png",
		"Portrait": Vector2i(4, 0),
	},
	Voter.MaleRed: {
		"Texture2D": "res://!project/art/male-red.png",
		"Portrait": Vector2i(5, 0),
	},
	Voter.MaleViolet: {
		"Texture2D": "res://!project/art/male-violet.png",
		"Portrait": Vector2i(0, 1),
	},
	Voter.MaleYellow: {
		"Texture2D": "res://!project/art/male-yellow.png",
		"Portrait": Vector2i(1, 1),
	},
	Voter.FemaleBlondeLilacSkirt: {
		"Texture2D": "res://!project/art/female_blonde_lilac_skirt.png",
		"Portrait": Vector2i(2, 1),
	},
	Voter.FemaleBlondeRoseSkirt: {
		"Texture2D": "res://!project/art/female_blonde_rose_skirt.png",
		"Portrait": Vector2i(3, 1),
	},
	Voter.FemaleBlondeWineSkirt: {
		"Texture2D": "res://!project/art/female_blonde_wine_skirt.png",
		"Portrait": Vector2i(4, 1),
	},
	Voter.FemaleBrunetteLilacSkirt: {
		"Texture2D": "res://!project/art/female_brunette_lilac_skirt.png",
		"Portrait": Vector2i(5, 1),
	},
	Voter.FemaleBrunetteRoseSkirt:{
		"Texture2D": "res://!project/art/female_brunette_rose_skirt.png",
		"Portrait": Vector2i(0, 2),
	},
	Voter.FemaleBrunetteWineSkirt: {
		"Texture2D": "res://!project/art/female_brunette_wine_skirt.png",
		"Portrait": Vector2i(1, 2),
	},
	Voter.FemaleShortHairBlondeLilacPants: {
		"Texture2D": "res://!project/art/female_shorthair_blonde_lilac_pants.png",
		"Portrait": Vector2i(2, 2),
	},
	Voter.FemaleShortHairBrunetteRosePants: {
		"Texture2D": "res://!project/art/female_shorthair_brunette_rose_pants.png",
		"Portrait": Vector2i(3, 2),
	}
}

#dialog busts, one cell of the atlas per voter (the "Portrait" of each VoterFactory entry) and per staffed stop
#the atlas is a grid of columns by rows, each cell sized from the atlas size so any atlas resolution works
var Portraits: Dictionary[String, Variant] = {
	"atlas": "res://!project/art/portraits/portraits.png",
	"columns": 6,
	"rows": 4,
}

#staff bust cell for each stop, keyed by the snake case stop name
var StaffPortraits: Dictionary[String, Vector2i] = {
	"lamp": Vector2i(4, 2),
	"id": Vector2i(5, 2),
	"list": Vector2i(0, 3),
	"spray": Vector2i(1, 3),
	"ballot": Vector2i(2, 3),
	"booth": Vector2i(3, 3),
}

var VoterIdleAnimations: Dictionary = {
	"Texture2D": VoterFactory[Voter.MaleCap]["Texture2D"],
	"Animation": { "Frames": {"Total": 37, "Hframes": 39, "Vframes": 5}, "Lenght": 1.3, "Step": 0.1,
	"Animations": {
			Direction.TopLeft:     { "Name": "top-left",     "Frame Coord": {"x": 0, "y": 4} },
			Direction.TopRight:    { "Name": "top-right",    "Frame Coord": {"x": 1, "y": 4} },
			Direction.BottomLeft:  { "Name": "bottom-left",  "Frame Coord": {"x": 3, "y": 4} },
			Direction.BottomRight: { "Name": "bottom-right", "Frame Coord": {"x": 2, "y": 4} },
		}
	},
}
