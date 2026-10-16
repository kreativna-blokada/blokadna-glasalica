##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Pixel loader: eight outlined blocks around a 3x3 grid, a dark head stepping clockwise with a fading trail
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
@tool
class_name PixelSpinner
extends Control

#grid cells of the ring, clockwise from the top left
const RING_CELLS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
	Vector2i(2, 2), Vector2i(1, 2), Vector2i(0, 2), Vector2i(0, 1),
]

@export var block_size: float = 16.0:
	set(value):
		block_size = value
		update_minimum_size()
		queue_redraw()
@export var block_gap: float = 3.0:
	set(value):
		block_gap = value
		update_minimum_size()
		queue_redraw()
@export var outline_width: float = 3.0
@export var outline_color: Color = Color(0.0862745, 0.0862745, 0.0862745, 1)
#fill of the head block first, then of the blocks trailing it
@export var trail_colors: Array[Color] = [
	Color(0.0862745, 0.0862745, 0.0862745, 1),
	Color(0.478431, 0.368627, 0.0941176, 1),
	Color(0.745098, 0.584314, 0.172549, 1),
]
@export var rest_color: Color = Color(0.913725, 0.85098, 0.65098, 1)
#s the head stays on one block
@export var step_time: float = 0.09

#private vars
var _head_index: int = 0
var _step_elapsed: float = 0.0

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

func _process(delta: float) -> void:
	_step_elapsed += delta
	if _step_elapsed < step_time:
		return
	_step_elapsed = fmod(_step_elapsed, step_time)
	_head_index = (_head_index + 1) % RING_CELLS.size()
	queue_redraw()

func _get_minimum_size() -> Vector2:
	var side: float = block_size * 3.0 + block_gap * 2.0
	return Vector2(side, side)

func _draw() -> void:
	var grid_side: float = block_size * 3.0 + block_gap * 2.0
	var origin: Vector2 = ((size - Vector2(grid_side, grid_side)) / 2.0).floor()
	for ring_index in RING_CELLS.size():
		var cell: Vector2i = RING_CELLS[ring_index]
		var block_rect: Rect2 = Rect2(origin + Vector2(cell) * (block_size + block_gap), Vector2(block_size, block_size))
		draw_rect(block_rect, outline_color)
		draw_rect(block_rect.grow(-outline_width), _block_color(ring_index))

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#the head block and the ones just behind it take the trail colors, the rest stay plain
func _block_color(ring_index: int) -> Color:
	var behind_head: int = posmod(_head_index - ring_index, RING_CELLS.size())
	return trail_colors[behind_head] if behind_head < trail_colors.size() else rest_color

#signal CanvasItem.visibility_changed => steps only while shown, starting again from the top left
func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree() and not Engine.is_editor_hint())
	_head_index = 0
	_step_elapsed = 0.0
	queue_redraw()
