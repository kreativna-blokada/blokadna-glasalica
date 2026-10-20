##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Team names and web version box slice glitching and vanishing, then slogan letters as pixel points flying into the throne shape
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name Thrones
extends Control

#throne shape the pixel points settle into, its dark pixels are their targets
const _THRONE_TEXTURE: Texture2D = preload("res://!project/art/UI/StartScreen/throne.svg")
#highest throne pixel brightness still counted as part of the throne, the backdrop around it is light grey
const _THRONE_DARKNESS: float = 0.5
#least red over green a screen pixel needs to count as a letter pixel, letter edges blending into white fall under it
const _LETTER_REDNESS: float = 0.25

#throne pixels row by row, as 0..1 shares of the throne texture size
var _throne_shares: PackedVector2Array
#pixel point start, its slogan, team or web version letter pixel, in Thrones space; slogan points come first
var _letter_positions: PackedVector2Array
#pixel point colours, the letter pixel colours
var _letter_colours: PackedColorArray
#slogan pixel points, the ones that fly into the throne
var _slogan_point_count: int = 0
#slogan pixel point end, its throne pixel, in Thrones space
var _throne_positions: PackedVector2Array
#s after the flight phase start the slogan pixel point begins to fly
var _flight_delays: PackedFloat32Array
#area of the team names and the web version box, its rows shift sideways in slices
var _slice_glitch_area: Rect2
#px each slice is shifted sideways by in the current glitch step
var _slice_shifts: PackedFloat32Array
#slice glitch step the slice shifts were rolled for
var _slice_glitch_step: int = -1
#team and web version pixel points still show, they vanish once the slice glitch ends
var _are_slice_glitch_points_shown: bool = false
#s since the crumble started
var _crumble_time: float = 0.0
#s the crumble lasts
var _crumble_duration: float = 0.0
#all slogan pixel points sit in the throne, it stands until a tap or the restore delay
var _is_throne_complete: bool = false
#s the complete throne has stood
var _throne_stand_time: float = 0.0
#area the throne is fitted into, a tap inside it restores the start screen
var _throne_area: Rect2

#onready vars
@onready var pixel_points: MultiMeshInstance2D = $PixelPoints

#samples the throne pixels once, nothing moves until a crumble starts
func _ready() -> void:
	set_process(false)
	_sample_throne_shares()

#slice glitches the team and web version points and then makes them vanish, flies the slogan points into the throne after that, restores the start screen once the complete throne has stood for the restore delay
func _process(delta: float) -> void:
	if _is_throne_complete:
		_throne_stand_time += delta
		if _throne_stand_time >= Configs.Thrones["restore_delay"]: _restore()
		return

	_crumble_time = minf(_crumble_time + delta, _crumble_duration)
	var slice_glitch_duration: float = Configs.Thrones["slice_glitch_share"] * _crumble_duration
	var pixel_multimesh: MultiMesh = pixel_points.multimesh

	for point_index: int in _slogan_point_count:
		pixel_multimesh.set_instance_transform_2d(point_index, Transform2D(0.0, _get_flight_position(point_index, slice_glitch_duration)))

	if _crumble_time < slice_glitch_duration:
		_roll_slice_shifts()
		for point_index: int in range(_slogan_point_count, _letter_positions.size()):
			pixel_multimesh.set_instance_transform_2d(point_index, Transform2D(0.0, _get_slice_glitch_position(point_index)))
	elif _are_slice_glitch_points_shown:
		_are_slice_glitch_points_shown = false
		for point_index: int in range(_slogan_point_count, _letter_positions.size()):
			pixel_multimesh.set_instance_color(point_index, Color.TRANSPARENT)

	if _crumble_time >= _crumble_duration: _is_throne_complete = true

#only the complete throne takes taps
func _has_point(point: Vector2) -> bool:
	return _is_throne_complete and _throne_area.has_point(point)

#a tap on the complete throne restores the start screen; touch only, mouse clicks arrive as emulated touch
func _gui_input(event: InputEvent) -> void:
	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if not touch_event or not touch_event.pressed: return

	_restore()
	accept_event()

#turns the slogan, team and shown web version letter pixels on screen into pixel points of the same colour; over the crumble duration the team names and web version box slice glitch and vanish, then the slogan crumbles into the throne set in the team area
func crumble(team_label: Control, slogan_label: Control, web_version_box: Control, crumble_duration: float) -> void:
	var team_area: Rect2 = _get_team_area(team_label)
	var slogan_area: Rect2 = get_global_transform().affine_inverse() * slogan_label.get_global_rect()
	_letter_positions.clear()
	_letter_colours.clear()
	_sample_letters(slogan_area, Configs.Thrones["slogan_point_spacing"])
	_slogan_point_count = _letter_positions.size()
	_sample_letters(team_area, Configs.Thrones["point_spacing"])
	_slice_glitch_area = team_area
	if web_version_box.visible:
		var web_version_area: Rect2 = get_global_transform().affine_inverse() * web_version_box.get_global_rect()
		_sample_letters(web_version_area, Configs.Thrones["point_spacing"])
		_slice_glitch_area = _slice_glitch_area.merge(web_version_area)
	_fit_throne_positions(team_area)

	var flight_duration: float = (1.0 - Configs.Thrones["slice_glitch_share"]) * crumble_duration
	var stagger_duration: float = Configs.Thrones["stagger_share"] * flight_duration
	_flight_delays.resize(_slogan_point_count)
	for point_index: int in _slogan_point_count:
		_flight_delays[point_index] = randf() * stagger_duration

	var point_count: int = _letter_positions.size()
	var pixel_multimesh: MultiMesh = pixel_points.multimesh
	pixel_multimesh.instance_count = point_count
	(pixel_multimesh.mesh as QuadMesh).size = Vector2.ONE * Configs.Thrones["point_spacing"]
	for point_index: int in point_count:
		pixel_multimesh.set_instance_color(point_index, _letter_colours[point_index])
		pixel_multimesh.set_instance_transform_2d(point_index, Transform2D(0.0, _letter_positions[point_index]))

	_slice_glitch_step = -1
	_are_slice_glitch_points_shown = true
	_crumble_time = 0.0
	_crumble_duration = crumble_duration
	_is_throne_complete = false
	_throne_stand_time = 0.0
	set_process(true)

#removes the pixel points and the throne they form
func clear() -> void:
	set_process(false)
	_is_throne_complete = false
	pixel_points.multimesh.instance_count = 0

#removes the throne and lets the start screen bring back the letters it replaced
func _restore() -> void:
	clear()
	Signals.throne_dismissed.emit()

#the pixel points are on screen, slice glitching, crumbling or sitting in the throne
func is_shown() -> bool:
	return pixel_points.multimesh.instance_count > 0

#keeps the throne pixels, every few texture px, as shares of the texture size
func _sample_throne_shares() -> void:
	var throne_image: Image = _THRONE_TEXTURE.get_image()
	if throne_image.is_compressed(): throne_image.decompress()
	var throne_size: Vector2 = throne_image.get_size()
	var sample_step: int = Configs.Thrones["throne_sample_step"]
	for row: int in range(0, throne_image.get_height(), sample_step):
		for column: int in range(0, throne_image.get_width(), sample_step):
			var throne_colour: Color = throne_image.get_pixel(column, row)
			if throne_colour.a > 0.5 and throne_colour.get_luminance() < _THRONE_DARKNESS:
				_throne_shares.append(Vector2(column, row) / throne_size)

#area of the team label and its title rows above it, in Thrones space
func _get_team_area(team_label: Control) -> Rect2:
	var team_area: Rect2 = team_label.get_global_rect()
	for title_row: Node in team_label.get_children():
		if title_row is Control: team_area = team_area.merge((title_row as Control).get_global_rect())
	return get_global_transform().affine_inverse() * team_area

#adds the letter pixels in the area of the last drawn frame every sample spacing px as pixel point starts, row by row, with their colours
func _sample_letters(letter_area: Rect2, sample_spacing: float) -> void:
	var screen_image: Image = get_viewport().get_texture().get_image()
	var screen_bounds: Rect2i = Rect2i(Vector2i.ZERO, screen_image.get_size())
	#Thrones space to screen image pixels, through the canvas and the window stretch
	var screen_transform: Transform2D = get_viewport().get_final_transform() * get_global_transform_with_canvas()
	for row: int in int(letter_area.size.y / sample_spacing):
		for column: int in int(letter_area.size.x / sample_spacing):
			var letter_position: Vector2 = letter_area.position + Vector2(column, row) * sample_spacing
			var screen_pixel: Vector2i = Vector2i(screen_transform * letter_position)
			if not screen_bounds.has_point(screen_pixel): continue

			var pixel_colour: Color = screen_image.get_pixelv(screen_pixel)
			if pixel_colour.r - pixel_colour.g < _LETTER_REDNESS: continue
			_letter_positions.append(letter_position)
			_letter_colours.append(pixel_colour)

#gives every slogan pixel point a throne pixel, the throne fitted into the team area and centred, row order kept so the slogan start builds the top of the throne
func _fit_throne_positions(team_area: Rect2) -> void:
	var throne_texture_size: Vector2 = _THRONE_TEXTURE.get_size()
	var throne_size: Vector2 = throne_texture_size * minf(team_area.size.x / throne_texture_size.x, team_area.size.y / throne_texture_size.y)
	var throne_corner: Vector2 = team_area.get_center() - throne_size / 2.0
	_throne_area = Rect2(throne_corner, throne_size)
	var throne_pixel_count: int = _throne_shares.size()
	_throne_positions.resize(_slogan_point_count)
	for point_index: int in _slogan_point_count:
		#jittered even pick, so the points spread over the whole throne without lining up in stripes
		var throne_pixel: int = mini(int((point_index + randf()) * throne_pixel_count / _slogan_point_count), throne_pixel_count - 1)
		_throne_positions[point_index] = throne_corner + _throne_shares[throne_pixel] * throne_size

#rolls new sideways shifts for the slices once per slice glitch step, some slices stay in place like a torn TV picture
func _roll_slice_shifts() -> void:
	var slice_glitch_step: int = int(_crumble_time / Configs.Thrones["slice_glitch_step_duration"])
	if slice_glitch_step == _slice_glitch_step: return

	_slice_glitch_step = slice_glitch_step
	var slice_shift: float = Configs.Thrones["slice_shift"]
	_slice_shifts.resize(ceili(_slice_glitch_area.size.y / Configs.Thrones["slice_height"]) + 1)
	for slice_index: int in _slice_shifts.size():
		_slice_shifts[slice_index] = randf_range(-slice_shift, slice_shift) if randf() < 0.5 else 0.0

#team or web version pixel point position now: its letter pixel shifted sideways with its slice
func _get_slice_glitch_position(point_index: int) -> Vector2:
	var slice_index: int = int((_letter_positions[point_index].y - _slice_glitch_area.position.y) / Configs.Thrones["slice_height"])
	return _letter_positions[point_index] + Vector2(_slice_shifts[clampi(slice_index, 0, _slice_shifts.size() - 1)], 0.0)

#slogan pixel point position now: waiting at its letter until the flight phase, then flying straight into its throne pixel to land exactly when the crumble ends
func _get_flight_position(point_index: int, flight_phase_start: float) -> Vector2:
	var flight_start: float = flight_phase_start + _flight_delays[point_index]
	var flight_progress: float = clampf((_crumble_time - flight_start) / (_crumble_duration - flight_start), 0.0, 1.0)
	return _letter_positions[point_index].lerp(_throne_positions[point_index], ease(flight_progress, -2.0))
