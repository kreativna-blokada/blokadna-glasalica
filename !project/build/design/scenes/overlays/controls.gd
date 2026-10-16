class_name Controls
extends CanvasLayer

#buttons resized or moved to follow the screen edges after a window resize
signal buttons_moved()

#CSS px per inch on phone browsers, which report their dpi as 96 for each device pixel per CSS px
const PHONE_BROWSER_CSS_DPI: float = 160.0

var _next_enabled_texture: Texture2D
var _next_disabled_texture: Texture2D

@onready var _next_button: TouchScreenButton = $Node/Next
@onready var _select_button: TouchScreenButton = $Selection/Select
@onready var _initiate_button: TouchScreenButton = $Selection/Initiate
@onready var _course_buttons: Array[TouchScreenButton] = [_select_button, _initiate_button]
@onready var _confirm_button: TouchScreenButton = $Validation/Confirm
@onready var _highlight_button: TouchScreenButton = $Validation/Highlight
@onready var _dialogue_buttons: Array[TouchScreenButton] = [_confirm_button, _highlight_button]
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
#px width of the dialog box, the buttons stay beside it
var _dialog_width: float = 0.0

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

	for classic_button in _classic_buttons:
		_classic_button_actions[classic_button] = classic_button.action
	_create_guide_border()
	set_dialog_open(false)

#the first Select press moves the guide border to Initiate, the first Initiate press hides it for good
func _input(event: InputEvent) -> void:
	if _guided_button == _select_button and event.is_action_pressed("select"):
		_fit_guide_border(_initiate_button)
	elif _guided_button == _initiate_button and event.is_action_pressed("initiate"):
		_hide_guide_border()

#scene shows the classic on-screen buttons by default; screen controls swap them for the next button
func init(stage: Stage, controller_type: Globals.ControllerType, dialog_width: float) -> void:
	if controller_type == Globals.ControllerType.Screen:
		for classic_button in _classic_buttons:
			classic_button.hide()
		_next_button.show()

	stage.next_voter_availability_updated.connect(set_next_enabled)
	set_next_enabled(stage.is_next_voter_available())

	_dialog_width = dialog_width
	_layout_buttons()
	#deferred so the right-anchored Validation group has followed the new screen edge first
	get_viewport().size_changed.connect(_layout_buttons, CONNECT_DEFERRED)

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
	for shown_button in _get_shown_buttons():
		var button_size: Vector2 = shown_button.texture_normal.get_size() * shown_button.global_scale
		var button_centre: Vector2 = shown_button.global_position + button_size / 2.0
		var spotlight_radius: float = maxf(button_size.x, button_size.y) / 2.0 + Configs.Spotlights["spotlight_padding"]
		button_spotlights.append(Vector3(button_centre.x, button_centre.y, spotlight_radius))
	return button_spotlights

#classic or next buttons the controller type keeps on screen
func _get_shown_buttons() -> Array[TouchScreenButton]:
	var shown_buttons: Array[TouchScreenButton] = []
	for button: TouchScreenButton in _classic_buttons + [_next_button]:
		if button.visible:
			shown_buttons.append(button)
	return shown_buttons

#sizes the classic buttons for the screen and lays both pairs out in its bottom corners, the upper button outside, the lower one inside
func _layout_buttons() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_insets: Vector3 = _get_screen_insets(screen_size)
	var left_margin: float = maxf(Configs.ClassicalControllers["button_edge_margin"], screen_insets.x)
	var right_margin: float = maxf(Configs.ClassicalControllers["button_edge_margin"], screen_insets.y)
	var bottom_margin: float = maxf(Configs.ClassicalControllers["button_bottom_margin"], screen_insets.z)
	var button_size: float = _get_button_size(screen_size.x, maxf(left_margin, right_margin))
	var button_gap: float = button_size * Configs.ClassicalControllers["button_gap_ratio"]
	var lower_y: float = screen_size.y - bottom_margin - button_size
	var upper_y: float = lower_y - Configs.ClassicalControllers["button_stagger"]

	_select_button.position = Vector2(left_margin, upper_y)
	_initiate_button.position = Vector2(left_margin + button_size + button_gap, lower_y)
	#the Validation group sits on the right screen edge, so its buttons go left of it
	_highlight_button.position = Vector2(-right_margin - button_size, upper_y)
	_confirm_button.position = Vector2(-right_margin - button_size * 2.0 - button_gap, lower_y)

	var texture_size: Vector2 = _select_button.texture_normal.get_size()
	var button_scale: float = button_size / texture_size.x
	var touch_shape := RectangleShape2D.new()
	touch_shape.size = texture_size + Vector2.ONE * Configs.ClassicalControllers["touch_padding"] * 2.0 / button_scale
	for classic_button in _classic_buttons:
		classic_button.scale = Vector2.ONE * button_scale
		classic_button.shape = touch_shape
		classic_button.shape_centered = true

	if _guided_button:
		_fit_guide_border(_guided_button)
	buttons_moved.emit()

#px button side: the texture size, grown on a mobile screen to the target thumb size, then shrunk to fit beside the dialog box
func _get_button_size(screen_width: float, side_margin: float) -> float:
	var button_size: float = _select_button.texture_normal.get_size().x
	var screen_height_mm: float = _get_screen_height_mm()
	if screen_height_mm > 0.0:
		var mobile_size: float = Configs.ClassicalControllers["button_target_mm"] / screen_height_mm * get_viewport().get_visible_rect().size.y
		button_size = maxf(button_size, mobile_size)

	#outer margin, two buttons and the gap between them, all within the room the dialog leaves on its side
	var side_room: float = (screen_width - _dialog_width) / 2.0 - Configs.ClassicalControllers["dialog_clearance"] - side_margin
	var fitting_size: float = side_room / (2.0 + Configs.ClassicalControllers["button_gap_ratio"])
	return clampf(minf(button_size, fitting_size), Configs.ClassicalControllers["button_min_size"], Configs.ClassicalControllers["button_max_size"])

#mm physical height of the canvas on a mobile screen, 0 on desktop where the buttons keep their texture size
func _get_screen_height_mm() -> float:
	if not _is_mobile_screen():
		return 0.0

	var screen_dpi: float = DisplayServer.screen_get_dpi()
	if screen_dpi <= 0.0:
		return 0.0
	if OS.has_feature("web"):
		screen_dpi = screen_dpi / 96.0 * PHONE_BROWSER_CSS_DPI
	return _get_canvas_screen_rect().size.y / screen_dpi * 25.4

#canvas px a display cutout takes from the left, right and bottom canvas edge in the mobile app, all 0 on desktop
#and in browsers, which keep the page clear of cutouts and report no real safe area
func _get_screen_insets(screen_size: Vector2) -> Vector3:
	if not OS.has_feature("mobile"):
		return Vector3.ZERO

	var canvas_rect: Rect2 = _get_canvas_screen_rect()
	var safe_area: Rect2 = DisplayServer.get_display_safe_area()
	if canvas_rect.size.y <= 0.0 or safe_area.size == Vector2.ZERO:
		return Vector3.ZERO
	#safe area comes in screen pixels, measured from the canvas edges so a cutout within a letterbox bar takes nothing
	var canvas_per_pixel: float = screen_size.y / canvas_rect.size.y
	return Vector3(
		maxf(0.0, safe_area.position.x - canvas_rect.position.x),
		maxf(0.0, canvas_rect.end.x - safe_area.end.x),
		maxf(0.0, canvas_rect.end.y - safe_area.end.y)) * canvas_per_pixel

#screen pixels the canvas covers, the window without the letterbox bars added on screens narrower than 16:9
func _get_canvas_screen_rect() -> Rect2:
	var stretch_transform: Transform2D = get_viewport().get_final_transform()
	var canvas_position: Vector2 = Vector2(DisplayServer.window_get_position()) + stretch_transform.origin
	return Rect2(canvas_position, get_viewport().get_visible_rect().size * stretch_transform.get_scale())

#true on a phone or tablet, in the app or in its browser
func _is_mobile_screen() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

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
