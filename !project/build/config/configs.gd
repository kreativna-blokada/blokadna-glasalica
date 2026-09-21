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
	#m/s² along device y axis, above gravity (~9.8)
	"threshold": 15.0,
	#up/down movements required to start the game
	"count": 8,
	#ms w/o a shake before the counter resets
	"timeout": 1500,
	#px the text jumps per shake
	"jump_height": 120.0,
	#s for one jump, up and back to rest
	"jump_duration": 0.5,
}
