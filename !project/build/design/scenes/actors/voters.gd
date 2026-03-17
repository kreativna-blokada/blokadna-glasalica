##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##                 FACTORY METHOD CLASS
#description     : Class for randomized generation of Voter characters
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
class_name VotersFactory
extends Node


#private vars
var _struct: PackedScene = preload("res://!project/build/design/scenes/actors/voter.tscn")
var _group: String = Globals.EntityProperties[Globals.Entity.Voter]["group"]

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

#constructor
func _init() -> void:
	pass

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#instanciates loaded scene and updates by listed resources
func load_voter(_index: int) -> Node:
	#instantiate the template scene
	var voter = _struct.instantiate()

	voter.add_to_group(_group)

	#set texture
	var texture = _get_texture(_index)
	voter.get_node("CharacterSprite").set_texture(texture)
	#var sprite = get_child(_index).duplicate()

	return voter

#dynimacally loaded instance's texture
func _get_texture(_index: int) -> Resource:
	var texture = Globals.VoterFactory[_index]["Texture2D"]
	return load(texture)
