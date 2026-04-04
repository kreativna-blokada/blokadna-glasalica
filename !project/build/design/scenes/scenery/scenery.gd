##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Scenery elements controller
#author          : Zeljko Vulovic
#date            : 20260326
#version         : 1.0
#===============================================================================
extends Node2D


func _on_entry_body_entered(_body: Node2D) -> void:
	$Setup/Entry.visible = false

func _on_entry_body_exited(_body: Node2D) -> void:
	$Setup/Entry.visible = true

func _on_exit_body_entered(_body: Node2D) -> void:
	$Setup/Exit.visible = false

func _on_exit_body_exited(_body: Node2D) -> void:
	$Setup/Exit.visible = true
