@tool
class_name PixelStyleBox
extends StyleBox

#flat box with a solid or dashed border, a hard offset shadow, an outer ring and inner bands along chosen edges

const SIDE_LEFT: int = 1
const SIDE_TOP: int = 2
const SIDE_RIGHT: int = 4
const SIDE_BOTTOM: int = 8

@export var bg_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var border_width: int = 0
@export_flags("Left", "Top", "Right", "Bottom") var border_sides: int = SIDE_LEFT | SIDE_TOP | SIDE_RIGHT | SIDE_BOTTOM
@export_group("Dashes")
@export var dashed: bool = false
#dash and gap lengths in border widths, evened out so each edge starts and ends with a dash
@export var dash_length: float = 3.0
@export var dash_gap: float = 2.0
@export_group("Shadow")
@export var shadow_color: Color = Color.TRANSPARENT
@export var shadow_offset: Vector2 = Vector2.ZERO
@export_group("Ring")
#solid band around the outside of the box, e.g. a focus ring
@export var ring_color: Color = Color.TRANSPARENT
@export var ring_width: int = 0
@export_group("Inset")
@export var inset_color: Color = Color.TRANSPARENT
@export var inset_width: int = 0
@export_flags("Left", "Top", "Right", "Bottom") var inset_sides: int = SIDE_RIGHT | SIDE_BOTTOM

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if ring_color.a > 0.0 and ring_width > 0:
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect.grow(ring_width), ring_color)
	if shadow_color.a > 0.0 and shadow_offset != Vector2.ZERO:
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + shadow_offset, rect.size), shadow_color)
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, bg_color)

	var inner: Rect2 = rect.grow_individual(-_side_width(SIDE_LEFT), -_side_width(SIDE_TOP), -_side_width(SIDE_RIGHT), -_side_width(SIDE_BOTTOM))
	if inset_color.a > 0.0 and inset_width > 0:
		if inset_sides & SIDE_LEFT:
			RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.position.x, inner.position.y, inset_width, inner.size.y), inset_color)
		if inset_sides & SIDE_TOP:
			RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.position.x, inner.position.y, inner.size.x, inset_width), inset_color)
		if inset_sides & SIDE_RIGHT:
			RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.end.x - inset_width, inner.position.y, inset_width, inner.size.y), inset_color)
		if inset_sides & SIDE_BOTTOM:
			RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.position.x, inner.end.y - inset_width, inner.size.x, inset_width), inset_color)

	if border_width <= 0:
		return
	var width: float = border_width
	#top and bottom edges span the full width, left and right ones fill in between them
	var top_width: float = _side_width(SIDE_TOP)
	var side_length: float = rect.size.y - top_width - _side_width(SIDE_BOTTOM)
	if border_sides & SIDE_TOP:
		_draw_edge(to_canvas_item, rect.position, Vector2.RIGHT, rect.size.x, width)
	if border_sides & SIDE_BOTTOM:
		_draw_edge(to_canvas_item, Vector2(rect.position.x, rect.end.y - width), Vector2.RIGHT, rect.size.x, width)
	if border_sides & SIDE_LEFT:
		_draw_edge(to_canvas_item, rect.position + Vector2(0, top_width), Vector2.DOWN, side_length, width)
	if border_sides & SIDE_RIGHT:
		_draw_edge(to_canvas_item, Vector2(rect.end.x - width, rect.position.y + top_width), Vector2.DOWN, side_length, width)

#the border width on one side, zero when that side has no border
func _side_width(side: int) -> float:
	return float(border_width) if border_sides & side else 0.0

func _draw_edge(to_canvas_item: RID, from: Vector2, direction: Vector2, length: float, width: float) -> void:
	var across: Vector2 = Vector2(direction.y, direction.x) * width
	if not dashed:
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(from, direction * length + across), border_color)
		return

	var dash: float = dash_length * width
	var gap: float = dash_gap * width
	var dash_count: int = maxi(1, roundi((length + gap) / (dash + gap)))
	var even_gap: float = (length - dash_count * dash) / (dash_count - 1) if dash_count > 1 else 0.0
	for i in dash_count:
		var start: Vector2 = from + direction * (i * (dash + even_gap))
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(start, direction * minf(dash, length) + across), border_color)
