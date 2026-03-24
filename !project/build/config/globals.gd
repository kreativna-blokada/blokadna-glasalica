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
		"group":	"actor",
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

var VoterStopsSound: Dictionary = {
	4: "res://!project/audio/round-one.mp3",
	5: "res://!project/audio/round-two.mp3",
	6: "res://!project/audio/round-two.mp3",
	7: "res://!project/audio/round-three.mp3",
	8: "res://!project/audio/round-four.mp3",
	10: "res://!project/audio/round-five.mp3",
	13: "res://!project/audio/choose-your-destiny.mp3",
}

var VoterIdleAnimations: Dictionary = {
	"Texture2D": "res://!project/art/player.png",
	"Animation": {
		Direction.TopLeft:     { "Name": "top-left",     "Frame Coord": {"x": 0, "y": 4} },
		Direction.TopRight:    { "Name": "top-right",    "Frame Coord": {"x": 1, "y": 4} },
		Direction.BottomLeft:  { "Name": "bottom-left",  "Frame Coord": {"x": 3, "y": 4} },
		Direction.BottomRight: { "Name": "bottom-right", "Frame Coord": {"x": 2, "y": 4} },
	},
}
