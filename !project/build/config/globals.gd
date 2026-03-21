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
	Blue,
	Brown,
	Green,
	Red,
	Teal,
	Lapis,
	Azure,
	Cobalt
}

var VoterFactory: Dictionary[Variant, Variant] = {
	Voter.Player: {
		"Texture2D": "res://!project/assets/art/player.png",
	},
	Voter.Blue: {
		"Texture2D": "res://!project/assets/art/player-blue.png",
	},
	Voter.Brown: {
		"Texture2D": "res://!project/assets/art/player-brown.png",
	},
	Voter.Green: {
		"Texture2D": "res://!project/assets/art/player-green.png",
	},
	Voter.Red: {
		"Texture2D": "res://!project/assets/art/player-red.png",
	},
	Voter.Teal: {
		"Texture2D": "res://!project/assets/art/player-teal.png",
	},
	Voter.Lapis: {
		"Texture2D": "res://!project/assets/art/player-lapis.png",
	},
	Voter.Azure: {
		"Texture2D": "res://!project/assets/art/player-azure.png",
	},
	Voter.Cobalt: {
		"Texture2D": "res://!project/assets/art/player-cobalt.png",
	},
}

var VoterStopsSound: Dictionary = {
	4: "res://!project/assets/audio/round-one.mp3",
	5: "res://!project/assets/audio/round-two.mp3",
	6: "res://!project/assets/audio/round-three.mp3",
	7: "res://!project/assets/audio/round-four.mp3",
	9: "res://!project/assets/audio/round-five.mp3",
	12: "res://!project/assets/audio/choose-your-destiny.mp3",
}

var VoterIdleAnimations: Dictionary = {
	"Texture2D": "res://!project/assets/art/player2.png",
	"Animation": {
		Direction.TopLeft:     { "Name": "top-left",     "Frame Coord": {"x": 0, "y": 4} },
		Direction.TopRight:    { "Name": "top-right",    "Frame Coord": {"x": 1, "y": 4} },
		Direction.BottomLeft:  { "Name": "bottom-left",  "Frame Coord": {"x": 3, "y": 4} },
		Direction.BottomRight: { "Name": "bottom-right", "Frame Coord": {"x": 2, "y": 4} },
	},
}