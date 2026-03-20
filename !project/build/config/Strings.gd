##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Curated registry of string literals
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
extends Node
#class_name Literals


const Signals: Dictionary[Variant, Variant] = {
	on_player_life_change = 'on_player_life_change',
	on_score_increase = 'on_score_increase',
	on_score_increment = 'on_score_increment',
	on_score_improve = 'on_score_improve'
}

const Animations: Dictionary[Variant, Variant] = {
	game_starts_animation = 'game_started'
}
