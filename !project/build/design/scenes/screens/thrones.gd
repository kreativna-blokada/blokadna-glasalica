##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Team and slogan letters turned into pixel points flying into the throne shape
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name Thrones
extends Control

#throne shape the pixel points settle into, its dark pixels are their targets
const _THRONE_TEXTURE: Texture2D = preload("res://!project/art/UI/StartScreen/throne.svg")
#highest throne pixel brightness still counted as part of the throne, the backdrop around it is light grey
const _THRONE_DARKNESS: float = 0.5
#least red over green a screen pixel needs to count as a team letter pixel, letter edges blending into white fall under it
const _LETTER_REDNESS: float = 0.25

#throne pixels row by row, as 0..1 shares of the throne texture size
var _throne_shares: PackedVector2Array
#pixel point start, its team or slogan letter pixel, in Thrones space
var _letter_positions: PackedVector2Array
#pixel point end, its throne pixel, in Thrones space
var _throne_positions: PackedVector2Array
#s after the crumble start the pixel point begins to fly
var _flight_delays: PackedFloat32Array
#s since the crumble started
var _crumble_time: float = 0.0
#s the crumble lasts
var _crumble_duration: float = 0.0

#onready vars
@onready var pixel_points: MultiMeshInstance2D = $PixelPoints

#samples the throne pixels once, nothing moves until a crumble starts
func _ready() -> void:
	set_process(false)
	_sample_throne_shares()

#moves every pixel point along its flight, stops once all of them sit in the throne
func _process(delta: float) -> void:
	_crumble_time = minf(_crumble_time + delta, _crumble_duration)
	for point_index: int in _letter_positions.size():
		pixel_points.multimesh.set_instance_transform_2d(point_index, Transform2D(0.0, _get_point_position(point_index)))

	if _crumble_time >= _crumble_duration: set_process(false)

#turns the team and slogan letter pixels on screen into pixel points of the same colour and crumbles them into the throne, set in the team area, over the crumble duration
func crumble(team_label: Control, slogan_label: Control, crumble_duration: float) -> void:
	var team_area: Rect2 = _get_team_area(team_label)
	var slogan_area: Rect2 = get_global_transform().affine_inverse() * slogan_label.get_global_rect()
	#slogan first, it sits above the team rows and builds the top of the throne
	_letter_positions.clear()
	var letter_colours: PackedColorArray = _sample_letters(slogan_area) + _sample_letters(team_area)
	_fit_throne_positions(team_area)

	var point_count: int = _letter_positions.size()
	_flight_delays.resize(point_count)
	var stagger_duration: float = Configs.Thrones["stagger_share"] * crumble_duration
	for point_index: int in point_count:
		_flight_delays[point_index] = randf() * stagger_duration

	var pixel_multimesh: MultiMesh = pixel_points.multimesh
	pixel_multimesh.instance_count = point_count
	(pixel_multimesh.mesh as QuadMesh).size = Vector2.ONE * Configs.Thrones["point_spacing"]
	for point_index: int in point_count:
		pixel_multimesh.set_instance_color(point_index, letter_colours[point_index])
		pixel_multimesh.set_instance_transform_2d(point_index, Transform2D(0.0, _letter_positions[point_index]))

	_crumble_time = 0.0
	_crumble_duration = crumble_duration
	set_process(true)

#removes the pixel points and the throne they form
func clear() -> void:
	set_process(false)
	pixel_points.multimesh.instance_count = 0

#the pixel points are on screen, crumbling or sitting in the throne
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

#adds the letter pixels in the area of the last drawn frame every point spacing px as pixel point starts, row by row, and returns their colours
func _sample_letters(letter_area: Rect2) -> PackedColorArray:
	var screen_image: Image = get_viewport().get_texture().get_image()
	var screen_bounds: Rect2i = Rect2i(Vector2i.ZERO, screen_image.get_size())
	#Thrones space to screen image pixels, through the canvas and the window stretch
	var screen_transform: Transform2D = get_viewport().get_final_transform() * get_global_transform_with_canvas()
	var point_spacing: float = Configs.Thrones["point_spacing"]
	var letter_colours: PackedColorArray = []
	for row: int in int(letter_area.size.y / point_spacing):
		for column: int in int(letter_area.size.x / point_spacing):
			var letter_position: Vector2 = letter_area.position + Vector2(column, row) * point_spacing
			var screen_pixel: Vector2i = Vector2i(screen_transform * letter_position)
			if not screen_bounds.has_point(screen_pixel): continue

			var pixel_colour: Color = screen_image.get_pixelv(screen_pixel)
			if pixel_colour.r - pixel_colour.g < _LETTER_REDNESS: continue
			_letter_positions.append(letter_position)
			letter_colours.append(pixel_colour)
	return letter_colours

#gives every pixel point a throne pixel, the throne fitted into the team area and centred, row order kept so top letters build the top of the throne
func _fit_throne_positions(team_area: Rect2) -> void:
	var throne_texture_size: Vector2 = _THRONE_TEXTURE.get_size()
	var throne_size: Vector2 = throne_texture_size * minf(team_area.size.x / throne_texture_size.x, team_area.size.y / throne_texture_size.y)
	var throne_corner: Vector2 = team_area.get_center() - throne_size / 2.0
	var point_count: int = _letter_positions.size()
	var throne_pixel_count: int = _throne_shares.size()
	_throne_positions.resize(point_count)
	for point_index: int in point_count:
		#jittered even pick, so the points spread over the whole throne without lining up in stripes
		var throne_pixel: int = mini(int((point_index + randf()) * throne_pixel_count / point_count), throne_pixel_count - 1)
		_throne_positions[point_index] = throne_corner + _throne_shares[throne_pixel] * throne_size

#pixel point position now: waiting at its letter, then flying straight into its throne pixel to land exactly when the crumble ends
func _get_point_position(point_index: int) -> Vector2:
	var flight_start: float = _flight_delays[point_index]
	var flight_progress: float = clampf((_crumble_time - flight_start) / (_crumble_duration - flight_start), 0.0, 1.0)
	return _letter_positions[point_index].lerp(_throne_positions[point_index], ease(flight_progress, -2.0))
