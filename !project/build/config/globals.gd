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
#gitignored, bundled into exports through the preset include filter
const RUNTIME_CREDENTIALS: String = "res://runtime_credentials.cfg"

enum Scene {
	Start,
	Game,
	Voter,
	Info,
	Playround
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
	}
}

#controls picked on the main menu controls row
enum Steering {
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

#outcome of a leaderboard score submission
enum ScoreSubmit {
	Accepted,
	Stored,
	Failed
}

#why the database did not give the player the username
enum NameRefuse {
	Taken,
	Failed
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
	},
	Voter.MaleBlue: {
		"Texture2D": "res://!project/art/male-blue.png",
	},
	Voter.MaleGreen: {
		"Texture2D": "res://!project/art/male-green.png",
	},
	Voter.MaleIndigo: {
		"Texture2D": "res://!project/art/male-indigo.png",
	},
	Voter.MaleMagenta: {
		"Texture2D": "res://!project/art/male-magenta.png",
	},
	Voter.MaleRed: {
		"Texture2D": "res://!project/art/male-red.png",
	},
	Voter.MaleViolet: {
		"Texture2D": "res://!project/art/male-violet.png",
	},
	Voter.MaleYellow: {
		"Texture2D": "res://!project/art/male-yellow.png",
	},
	Voter.FemaleBlondeLilacSkirt: {
		"Texture2D": "res://!project/art/female_blonde_lilac_skirt.png",
	},
	Voter.FemaleBlondeRoseSkirt: {
		"Texture2D": "res://!project/art/female_blonde_rose_skirt.png",
	},
	Voter.FemaleBlondeWineSkirt: {
		"Texture2D": "res://!project/art/female_blonde_wine_skirt.png",
	},
	Voter.FemaleBrunetteLilacSkirt: {
		"Texture2D": "res://!project/art/female_brunette_lilac_skirt.png",
	},
	Voter.FemaleBrunetteRoseSkirt:{
		"Texture2D": "res://!project/art/female_brunette_rose_skirt.png",
	},
	Voter.FemaleBrunetteWineSkirt: {
		"Texture2D": "res://!project/art/female_brunette_wine_skirt.png",
	},
	Voter.FemaleShortHairBlondeLilacPants: {
		"Texture2D": "res://!project/art/female_shorthair_blonde_lilac_pants.png",
	},
	Voter.FemaleShortHairBrunetteRosePants: {
		"Texture2D": "res://!project/art/female_shorthair_brunette_rose_pants.png",
	}
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
