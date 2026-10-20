##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Start screen, screen manager
#maintainer      : Nemanja, Zeljko
#version         : 1.1
#===============================================================================
extends Node

#broadcast vars
var current_scene: Node = null

#private vars
var _suspended_scene: Node = null

func _ready():
	var root: Window = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

#switches to the scene; suspends the scene instead of freeing
func switch_scene(path, is_switch_transient: bool = false):
	_deferred_goto_scene.call_deferred(path, is_switch_transient)

#brings back the kept scene when path matches it, otherwise loads path; then keeps or frees the scene left
func _deferred_goto_scene(path, is_switch_transient: bool):
	var departing_scene: Node = current_scene
	if _suspended_scene and _suspended_scene.scene_file_path == path:
		current_scene = _suspended_scene
		_suspended_scene = null
		_set_scene_suspended(current_scene, false)
	else:
		if _suspended_scene:
			_suspended_scene.free()
			_suspended_scene = null
		# Load the new scene.
		var scene_resource: PackedScene = ResourceLoader.load(path) as PackedScene
		# Instance the new scene.
		current_scene = scene_resource.instantiate()
		# Add it to the active scene, as child of root.
		get_tree().get_root().add_child(current_scene)

	if is_switch_transient:
		_suspended_scene = departing_scene
		_set_scene_suspended(departing_scene, true)
	else:
		# It is now safe to remove the departing scene
		departing_scene.free()

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)

#hides the scene and stops its processing, input, tweens, animations and sound, or brings them all back
func _set_scene_suspended(target_scene: Node, is_suspended: bool) -> void:
	target_scene.process_mode = Node.PROCESS_MODE_DISABLED if is_suspended else Node.PROCESS_MODE_INHERIT
	if target_scene is CanvasItem:
		target_scene.visible = not is_suspended
