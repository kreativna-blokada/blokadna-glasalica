##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Actor placehoder
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
class_name VotingStop
extends Node2D

var occupant : Character = null

func is_free() -> bool:
	return occupant == null

func free_up() -> void:
	occupant = null

func occupy(character: Character) -> void:
	occupant = character
