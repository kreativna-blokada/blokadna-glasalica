##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Gameplay configuration settings
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
extends Node


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
		"speed": 200,
		"lives": 0
	}
}

var Shake: Dictionary[String, Variant] = {
	#up/down movements required to start the game
	"count": 8,
	#ms w/o a shake before the counter resets
	"timeout": 1500,
	#m/s² along device y axis, above gravity (~9.8)
	"shake_threshold": 15.0,
	#px the text jumps per shake
	"jump_height": 120.0,
	#s for one jump, up and back to rest
	"jump_duration": 0.5,
	#px the phone must be dragged up/down to count as a shake, web only
	"drag_threshold": 50.0,
	#px the phone can be dragged up/down at most, web only
	"drag_limit": 100.0,
}

var Round: Dictionary[String, Variant] = {
	#s a run lasts before the score is submitted and the leaderboard opens
	"duration": 180.0,
}

var Leaderboard: Dictionary[String, Variant] = {
	#debug firebase database endpoint, public on purpose; its rules get locked once the game is public
	"debug_endpoint": "https://glasalica-default-rtdb.europe-west1.firebasedatabase.app/",
	#number of best scores fetched for the leaderboard
	"top_count": 10,
	#must match the length limit in the database rules
	"username_length": 20,
	#s before a leaderboard request gives up
	"request_timeout": 10.0,
}
