##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Playground behaves identically to game.tscn,
#				   when open playground.tscn and run it (F6), it will:
#				   1) Load game.tscn via Globals.Scenes["path"]
#				   2) Instantiate and add it as a child of Playground
#				   3) The entire game tree runs exactly as if game.tscn was launched directly
#				   All internal references work because owner, $ paths, and % unique names resolve within the game scene's own tree.
#				   The playground's existing test nodes will still be visible underneath — for hiding them, one can either remove them from playground.tscn in the editor, or add hide() before the add_child call in _ready().
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name Playground
extends Node2D

func _ready() -> void:
	# loads the full main game(play) scene so playground runs identically to game scene
	var game_scene: PackedScene = load(Globals.Scenes[Globals.Scene.Game]["path"])
	var game_instance: Node = game_scene.instantiate()
	add_child(game_instance)

func _process(_delta: float) -> void:
	pass
