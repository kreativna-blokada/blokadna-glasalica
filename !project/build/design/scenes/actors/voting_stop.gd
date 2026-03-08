class_name VotingStop
extends Node2D

var occupant : Character = null

func is_free() -> bool:
	return occupant == null

func free_up() -> void:
	occupant = null

func occupy(voter: Character) -> void:
	occupant = voter
