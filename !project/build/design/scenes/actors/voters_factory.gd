##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##                 FACTORY METHOD CLASS
#description     : Class for randomized generation of Voter characters
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
class_name VotersFactory
extends Node

#private vars
var _voter_scene: PackedScene = preload("res://!project/build/design/scenes/actors/voter.tscn")
var _voter_group: String = Globals.EntityProperties[Globals.Entity.Voter]["group"]

var _voter_scene_struct: Dictionary = Globals.Scenes[Globals.Scene.Voter]["structure"]

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

#instanciates loaded scene updated by listed resources
func load_voter(_index: int) -> Node:
	#instantiate the template scene
	var voter: Node = _voter_scene.instantiate()

	voter.voter_factory_index = _index
	voter.add_to_group(_voter_group)

	#set texture
	var texture: Resource = _get_texture(_index)
	var _voter_scene_sprite = _voter_scene_struct["sprite"]
	voter.get_node(_voter_scene_sprite).set_texture(texture)

	return voter

#dynimacally loaded instance's texture
func _get_texture(_index: int) -> Resource:
	var texture_path: String = Globals.VoterFactory[_index]["Texture2D"]
	if not ResourceLoader.exists(texture_path, "Texture2D"):
		texture_path = Globals.VoterFactory[Globals.Voter.Player]["Texture2D"]
	return load(texture_path)
