@tool
extends EditorPlugin

const MENU_ITEM: String = "Build Dialogue Package"
const DialoguePackageBuilder = preload("res://addons/dialogue_packager/dialogue_package_builder.gd")
const DialogueArchiveExportPlugin = preload(
	"res://addons/dialogue_packager/dialogue_archive_export_plugin.gd"
)

var _archive_export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM, _build_dialogue_package)
	_archive_export_plugin = DialogueArchiveExportPlugin.new()
	add_export_plugin(_archive_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_archive_export_plugin)
	_archive_export_plugin = null
	remove_tool_menu_item(MENU_ITEM)


func _build_dialogue_package() -> void:
	var error: Error = DialoguePackageBuilder.build()
	if error == OK:
		get_editor_interface().get_resource_filesystem().scan()
	else:
		push_error("[DIALOGUE PACKAGER] Build failed: %s" % error_string(error))
