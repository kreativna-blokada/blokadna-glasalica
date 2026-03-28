##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Global configurations loader
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
extends Node


const PATH: String = "res://!project/build/config/globals.gd"

enum Scene {
	Game,
	Voter,
	Info,
	Playround
}

var Scenes: Dictionary[Variant, Variant] = {
	Scene.Game: {
		"path": "res://!project/build/design/scenes/game.tscn"
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
	}
}

#GAMEPLAY
# ██████╗  █████╗ ███╗   ███╗███████╗██████╗ ██╗      █████╗ ██╗   ██╗
#██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝
#██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝██║     ███████║ ╚████╔╝
#██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔═══╝ ██║     ██╔══██║  ╚██╔╝
#╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║     ███████╗██║  ██║   ██║
# ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝

enum Direction {
	TopLeft,
	TopRight,
	BottomLeft,
	BottomRight,
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
	Player,
	Black,
	Blue,
	Green,
	Indigo,
	Magenta,
	Red,
	Violet,
	Yellow
}

var VoterFactory: Dictionary[Variant, Variant] = {
	Voter.Player: {
		"Texture2D": "res://!project/art/player2.png",
	},
	Voter.Black: {
		"Texture2D": "res://!project/art/player-black.png",
	},
	Voter.Blue: {
		"Texture2D": "res://!project/art/player-blue.png",
	},
	Voter.Green: {
		"Texture2D": "res://!project/art/player-green.png",
	},
	Voter.Indigo: {
		"Texture2D": "res://!project/art/player-indigo.png",
	},
	Voter.Magenta: {
		"Texture2D": "res://!project/art/player-magenta.png",
	},
	Voter.Red: {
		"Texture2D": "res://!project/art/player-red.png",
	},
	Voter.Violet: {
		"Texture2D": "res://!project/art/player-violet.png",
	},
	Voter.Yellow: {
		"Texture2D": "res://!project/art/player-yellow.png",
	},
}

var VoterStops: Dictionary = {
	"stops":		[3, 4, 5, 6, 7, 9, 12],
	"queue":		1,
	"group":		"voting_course"
} #todo: move to configs, not globals
var VoterStopsSounds: Dictionary = { # sounds values = stops index + one voter queue
	VoterStops["stops"][0] + VoterStops["queue"]: "res://!project/audio/alexzavesa-double-woosh-1-463575.mp3",
	VoterStops["stops"][1] + VoterStops["queue"]: "res://!project/audio/alexzavesa-electric-boom-1-463651.mp3",
	VoterStops["stops"][2] + VoterStops["queue"]: "res://!project/audio/alexzavesa-electronic-impact-stomps-4-463657.mp3",
	VoterStops["stops"][3] + VoterStops["queue"]: "res://!project/audio/alexzavesa-future-game-glitch-1-463641.mp3",
	VoterStops["stops"][4] + VoterStops["queue"]: "res://!project/audio/alexzavesa-future-game-glitch-2-463631.mp3",
	VoterStops["stops"][5] + VoterStops["queue"]: "res://!project/audio/alexzavesa-future-game-glitch-10-463642.mp3",
	VoterStops["stops"][6] + VoterStops["queue"]: "res://!project/audio/alexzavesa-glitch-3-463646.mp3",
}
var VotingCourse: Array = VoterStops["stops"].map(func(index): return index + VoterStops["queue"])

var VoterIdleAnimations: Dictionary = {
	"Texture2D": VoterFactory[Voter.Player]["Texture2D"],
	"Animation": { "Frames": {"Total": 37, "Hframes": 39, "Vframes": 5}, "Lenght": 1.3, "Step": 0.1,
	"Animations": {
			Direction.TopLeft:     { "Name": "top-left",     "Frame Coord": {"x": 0, "y": 4} },
			Direction.TopRight:    { "Name": "top-right",    "Frame Coord": {"x": 1, "y": 4} },
			Direction.BottomLeft:  { "Name": "bottom-left",  "Frame Coord": {"x": 3, "y": 4} },
			Direction.BottomRight: { "Name": "bottom-right", "Frame Coord": {"x": 2, "y": 4} },
		}
	},
}
