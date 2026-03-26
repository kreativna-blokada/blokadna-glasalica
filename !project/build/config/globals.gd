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
		"Texture2D": "res://!project/art/player.png",
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
}
var VoterStopsSounds: Dictionary = { # sounds values = stops index + one voter queue
	VoterStops["stops"][0] + VoterStops["queue"]: "res://!project/audio/bubblegum.mp3",
	VoterStops["stops"][1] + VoterStops["queue"]: "res://!project/audio/Maximus Decimus Meridius.mp3",
	VoterStops["stops"][2] + VoterStops["queue"]: "res://!project/audio/Wookiees.mp3",
	VoterStops["stops"][3] + VoterStops["queue"]: "res://!project/audio/lack of faith.mp3",
	VoterStops["stops"][4] + VoterStops["queue"]: "res://!project/audio/Dark Side.mp3",
	VoterStops["stops"][5] + VoterStops["queue"]: "res://!project/audio/deal.mp3",
	VoterStops["stops"][6] + VoterStops["queue"]: "res://!project/audio/try.mp3",
}
var VotingCourse: Array = VoterStops["stops"].map(func(index): return index + VoterStops["queue"])

var VoterIdleAnimations: Dictionary = {
	"Texture2D": "res://!project/art/player.png",
	"Animation": {
		Direction.TopLeft:     { "Name": "top-left",     "Frame Coord": {"x": 0, "y": 4} },
		Direction.TopRight:    { "Name": "top-right",    "Frame Coord": {"x": 1, "y": 4} },
		Direction.BottomLeft:  { "Name": "bottom-left",  "Frame Coord": {"x": 3, "y": 4} },
		Direction.BottomRight: { "Name": "bottom-right", "Frame Coord": {"x": 2, "y": 4} },
	},
}
