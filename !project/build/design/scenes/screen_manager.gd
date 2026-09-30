extends Node

var current_scene: Node = null

func _ready():
	var root: Window = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func switch_scene(path):
	_deferred_goto_scene.call_deferred(path)

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s: PackedScene = ResourceLoader.load(path) as PackedScene

	# Instance the new scene.
	current_scene = s.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
