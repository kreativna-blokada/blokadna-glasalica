class_name Controls
extends CanvasLayer

#Confirm and Highlight moved to follow the right screen edge after a window resize
signal buttons_moved()

var _next_enabled_texture: Texture2D
var _next_disabled_texture: Texture2D

@onready var _next_button: TouchScreenButton = $Node/Next
@onready var _select_button: TouchScreenButton = $Selection/Select
@onready var _initiate_button: TouchScreenButton = $Selection/Initiate
@onready var _course_buttons: Array[TouchScreenButton] = [$Selection/Select, $Selection/Initiate]
@onready var _dialogue_buttons_group: Node2D = $Validation
@onready var _dialogue_buttons: Array[TouchScreenButton] = [$Validation/Confirm, $Validation/Highlight]
@onready var _classic_buttons: Array[TouchScreenButton] = _course_buttons + _dialogue_buttons

#action each button fires while its state is played, kept while the button is inactive
var _classic_button_actions: Dictionary[TouchScreenButton, String] = {}

#gold border guiding the first run: around Select once the first voter stops in the queue, then around Initiate until it is pressed
var _guide_border: Panel
var _guide_border_pulse: Tween
#button the guide border is around right now; null once the guide is over
var _guided_button: TouchScreenButton
#true while a dialog is open, so the guide border never pulses over the dialogue buttons' turn
var _is_dialog_open: bool = false

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

	for classic_button in _classic_buttons:
		_classic_button_actions[classic_button] = classic_button.action
	_create_guide_border()
	set_dialog_open(false)

	get_viewport().size_changed.connect(_pin_dialogue_buttons_to_right_edge)
	_pin_dialogue_buttons_to_right_edge()

#keeps Confirm and Highlight at their design distance from the right edge on screens wider than the design width
func _pin_dialogue_buttons_to_right_edge() -> void:
	var design_width: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	_dialogue_buttons_group.position.x = get_viewport().get_visible_rect().size.x - design_width
	buttons_moved.emit()

#the first Select press moves the guide border to Initiate, the first Initiate press hides it for good
func _input(event: InputEvent) -> void:
	if _guided_button == _select_button and event.is_action_pressed("select"):
		_fit_guide_border(_initiate_button)
	elif _guided_button == _initiate_button and event.is_action_pressed("initiate"):
		_hide_guide_border()

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
	_is_dialog_open = is_dialog_open
	if is_dialog_open and _guided_button:
		_hide_guide_border()
	for course_button in _course_buttons:
		_set_classic_button_active(course_button, not is_dialog_open)
	for dialog_button in _dialogue_buttons:
		_set_classic_button_active(dialog_button, is_dialog_open)

#centre and radius of every shown button in canvas pixels, for the dialog dim to leave uncovered
func get_button_spotlights() -> PackedVector3Array:
	var button_spotlights: PackedVector3Array = []
	for shown_button: TouchScreenButton in _classic_buttons + [_next_button]:
		if not shown_button.visible: continue

		var button_size: Vector2 = shown_button.texture_normal.get_size() * shown_button.global_scale
		var button_centre: Vector2 = shown_button.global_position + button_size / 2.0
		var spotlight_radius: float = maxf(button_size.x, button_size.y) / 2.0 + Configs.Spotlights["spotlight_padding"]
		button_spotlights.append(Vector3(button_centre.x, button_centre.y, spotlight_radius))
	return button_spotlights

#an inactive button is see-through and has no action to fire
func _set_classic_button_active(classic_button: TouchScreenButton, is_active: bool) -> void:
	classic_button.modulate.a = 1.0 if is_active else Configs.ClassicalControllers["inactive_buttons_opacity"]
	classic_button.action = _classic_button_actions[classic_button] if is_active else ""


#builds the hidden gold border the guide moves from Select to Initiate
func _create_guide_border() -> void:
	var border_style := StyleBoxFlat.new()
	border_style.draw_center = false
	border_style.border_color = Configs.ClassicalControllers["guide_border_color"]
	border_style.set_border_width_all(Configs.ClassicalControllers["guide_border_width"])
	border_style.set_corner_radius_all(Configs.ClassicalControllers["guide_border_radius"])

	_guide_border = Panel.new()
	_guide_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide_border.add_theme_stylebox_override("panel", border_style)
	_guide_border.hide()
	add_child(_guide_border)

#places the guide border around the given button
func _fit_guide_border(guided_button: TouchScreenButton) -> void:
	_guided_button = guided_button
	var border_gap: float = Configs.ClassicalControllers["guide_border_gap"]
	_guide_border.position = guided_button.global_position - Vector2(border_gap, border_gap)
	_guide_border.size = guided_button.texture_normal.get_size() * guided_button.global_scale + Vector2(border_gap, border_gap) * 2

#shows the pulsing guide border around Select while it is on screen, prompting the first selection
func show_guide_border() -> void:
	_pulse_guide_border_around(_select_button)

#shows the pulsing guide border around Initiate while it is on screen, prompting the start at a station
func show_initiate_guide_border() -> void:
	_pulse_guide_border_around(_initiate_button)

#fits the guide border around the given button and pulses it there
func _pulse_guide_border_around(guided_button: TouchScreenButton) -> void:
	if _is_dialog_open or not guided_button.visible: return

	if _guide_border_pulse:
		_guide_border_pulse.kill()
	_fit_guide_border(guided_button)
	_guide_border.modulate.a = 1.0
	_guide_border.show()
	var pulse_duration: float = Configs.ClassicalControllers["guide_border_pulse"]
	if pulse_duration <= 0.0: return

	_guide_border_pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_guide_border_pulse.tween_property(_guide_border, "modulate:a", Configs.ClassicalControllers["guide_border_faded_opacity"], pulse_duration / 2.0)
	_guide_border_pulse.tween_property(_guide_border, "modulate:a", 1.0, pulse_duration / 2.0)

#stops the pulse and hides the guide border
func _hide_guide_border() -> void:
	if _guide_border_pulse:
		_guide_border_pulse.kill()
	_guided_button = null
	_guide_border.hide()
