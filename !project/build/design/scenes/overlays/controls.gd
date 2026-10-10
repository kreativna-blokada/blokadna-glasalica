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

#gold borders drawn over the dialog dimming around Confirm and Highlight, while a dialog is open
var _dialogue_border_layer: CanvasLayer
var _dialogue_borders: Control
var _dialogue_border_pulse: Tween

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

	for classic_button in _classic_buttons:
		_classic_button_actions[classic_button] = classic_button.action
	_create_dialogue_borders()
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
	_show_dialogue_borders(is_dialog_open)

#an inactive button is see-through and has no action to fire
func _set_classic_button_active(classic_button: TouchScreenButton, is_active: bool) -> void:
	classic_button.modulate.a = 1.0 if is_active else Configs.ClassicalControllers["inactive_buttons_opacity"]
	classic_button.action = _classic_button_actions[classic_button] if is_active else ""


#builds a gold border around each dialogue button, on a layer above the dialog dimming
func _create_dialogue_borders() -> void:
	_dialogue_border_layer = CanvasLayer.new()
	_dialogue_border_layer.layer = Configs.ClassicalControllers["dialogue_border_layer"]
	add_child(_dialogue_border_layer)

	_dialogue_borders = Control.new()
	_dialogue_borders.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_border_layer.add_child(_dialogue_borders)

	var border_style := StyleBoxFlat.new()
	border_style.draw_center = false
	border_style.border_color = Configs.ClassicalControllers["dialogue_border_color"]
	border_style.set_border_width_all(Configs.ClassicalControllers["dialogue_border_width"])
	border_style.set_corner_radius_all(Configs.ClassicalControllers["dialogue_border_radius"])

	var border_gap: float = Configs.ClassicalControllers["dialogue_border_gap"]
	for dialog_button in _dialogue_buttons:
		var button_border := Panel.new()
		button_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button_border.add_theme_stylebox_override("panel", border_style)
		button_border.position = dialog_button.position - Vector2(border_gap, border_gap)
		button_border.size = dialog_button.texture_normal.get_size() * dialog_button.scale + Vector2(border_gap, border_gap) * 2
		_dialogue_borders.add_child(button_border)

#shows the dialogue button borders only for visible classic buttons, pulsing while shown
func _show_dialogue_borders(is_shown: bool) -> void:
	if _dialogue_border_pulse:
		_dialogue_border_pulse.kill()
	_dialogue_borders.modulate.a = 1.0

	var border_index: int = 0
	for dialog_button in _dialogue_buttons:
		_dialogue_borders.get_child(border_index).visible = is_shown and dialog_button.visible
		border_index += 1

	var pulse_duration: float = Configs.ClassicalControllers["dialogue_border_pulse"]
	if not is_shown or pulse_duration <= 0.0: return

	_dialogue_border_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_dialogue_border_pulse.tween_property(_dialogue_borders, "modulate:a", Configs.ClassicalControllers["dialogue_border_faded_opacity"], pulse_duration / 2.0)
	_dialogue_border_pulse.tween_property(_dialogue_borders, "modulate:a", 1.0, pulse_duration / 2.0)
