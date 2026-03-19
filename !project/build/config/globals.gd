##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Global configurations loader
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
extends Node


const PATH = "res://!project/build/config/globals.gd"

enum Scene {
	Menu,
	Game,
	Level,
	Player,
	Enemy,
	Voter,
	Playround
}

enum Level {
	Caciland
}

var Scenes = {
	Scene.Menu: {
		"path": "res://!project/design/scenes/UI/menu.tscn"
	},
	Scene.Game: {
		"path": "res://!project/build/design/scenes/game.tscn"
	},
	Scene.Level: {
		Level.Caciland: {
			"path": "res://!project/design/scenes/levels/01_caciland.tscn"
		},
	},	
	Scene.Player: {
		"path": "res://characters/player/player.tscn"
	},
	Scene.Enemy: {
		"path": "res://characters/enemies/enemy.tscn"
	},
	Scene.Voter: {
		"path": "res://!project/build/design/scenes/actors/voter.tscn"
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

enum Perks {
	Score
}

enum Quirks {
	Spawn
}

var TraitsProperties = {
	Quirks.Spawn: {
		"time": { "min": Configs.TraitsProperties[Configs.Quirks.Spawn]["time"]["min"], 
				  "max": Configs.TraitsProperties[Configs.Quirks.Spawn]["time"]["max"]},
		"step": { "min": Configs.TraitsProperties[Configs.Quirks.Spawn]["step"]["min"], 
				  "max": Configs.TraitsProperties[Configs.Quirks.Spawn]["step"]["max"]}
	}
}

var TraitsRelation = {
	Perks.Score: {
		# Score -> Spawn
		Quirks.Spawn:	{
			"step": { "min": Configs.TraitsRelation[Configs.Perks.Score][Configs.Quirks.Spawn]["step"]["min"], 
					  "max": Configs.TraitsRelation[Configs.Perks.Score][Configs.Quirks.Spawn]["step"]["max"]}
		}
	}
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

var EntityProperties = {
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
	Blue,
	Brown,
	Green,
	Red,
	Teal,
	Lapis,
	Azure,
	Cobalt
}

var VoterFactory = {
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
	3: "res://!project/assets/audio/round-one.mp3",
	4: "res://!project/assets/audio/round-two.mp3",
	5: "res://!project/assets/audio/round-three.mp3",
	6: "res://!project/assets/audio/round-four.mp3",
	8: "res://!project/assets/audio/round-five.mp3",
	11: "res://!project/assets/audio/choose-your-destiny.mp3",
}
