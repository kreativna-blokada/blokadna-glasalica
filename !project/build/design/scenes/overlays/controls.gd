class_name Controls
extends CanvasLayer

var _next_enabled_texture: Texture2D
var _next_disabled_texture: Texture2D

@onready var _next_button: TouchScreenButton = $Node/Next
@onready var _course_buttons: Array[TouchScreenButton] = [$Selection/Select, $Selection/Initiate]
@onready var _dialogue_buttons: Array[TouchScreenButton] = [$Validation/Confirm, $Validation/Highlight]
@onready var _classic_buttons: Array[TouchScreenButton] = _course_buttons + _dialogue_buttons

#action each button fires while its state is played, kept while the button is inactive
var _classic_button_actions: Dictionary[TouchScreenButton, String] = {}

#buttons are drawn as light line silhouettes above the dialog dimming while a dialog is open
var _regular_layer: int
var _silhouette_material: ShaderMaterial

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

	for classic_button in _classic_buttons:
		_classic_button_actions[classic_button] = classic_button.action

	_regular_layer = layer
	_silhouette_material = _create_silhouette_material()
	set_dialog_open(false)

#scene shows the classic on-screen buttons by default; screen controls swap them for the next button
func init(stage: Stage, controller_type: Globals.ControllerType) -> void:
	if controller_type == Globals.ControllerType.Screen:
		for classic_button in _classic_buttons:
			classic_button.hide()
		_next_button.show()

	stage.next_voter_availability_updated.connect(set_next_enabled)
	set_next_enabled(stage.is_next_voter_available())

func set_next_enabled(is_enabled: bool) -> void:
	_next_button.texture_normal = _next_enabled_texture if is_enabled else _next_disabled_texture
	_next_button.texture_pressed = _next_disabled_texture

#Select and Initiate work outside a dialog, Confirm and Highlight inside it; the other pair is dimmed and fires nothing
func set_dialog_open(is_dialog_open: bool) -> void:
	for course_button in _course_buttons:
		_set_classic_button_active(course_button, not is_dialog_open)
	for dialog_button in _dialogue_buttons:
		_set_classic_button_active(dialog_button, is_dialog_open)
	_show_silhouettes(is_dialog_open)

#an inactive button is see-through and has no action to fire
func _set_classic_button_active(classic_button: TouchScreenButton, is_active: bool) -> void:
	classic_button.modulate.a = 1.0 if is_active else Configs.ClassicalControllers["inactive_buttons_opacity"]
	classic_button.action = _classic_button_actions[classic_button] if is_active else ""

#material keeping only the dark lines of a button, drawn in a light colour
func _create_silhouette_material() -> ShaderMaterial:
	var silhouette_material := ShaderMaterial.new()
	silhouette_material.shader = load("res://!project/art/shaders/silhouette.gdshader")
	silhouette_material.set_shader_parameter("silhouette_color", Configs.ClassicalControllers["dialogue_silhouette_color"])
	silhouette_material.set_shader_parameter("line_brightness_limit", Configs.ClassicalControllers["dialogue_silhouette_line_brightness"])
	return silhouette_material

#lifts the buttons above the dialog dimming as silhouettes, or puts them back to their regular look
func _show_silhouettes(is_shown: bool) -> void:
	layer = Configs.ClassicalControllers["dialogue_silhouette_layer"] if is_shown else _regular_layer
	for any_button in _classic_buttons + [_next_button]:
		any_button.material = _silhouette_material if is_shown else null
