extends SceneTree

const DialoguePackageBuilder = preload("res://addons/dialogue_packager/dialogue_package_builder.gd")


func _init() -> void:
	var error: Error = DialoguePackageBuilder.build()
	quit(0 if error == OK else 1)
