@tool
class_name PixelStyleBox
extends StyleBox

#flat box with a solid or dashed border, a hard offset shadow and an inner bottom-right band

@export var bg_color: Color = Color.WHITE
@export var border_color: Color = Color.BLACK
@export var border_width: int = 0
@export_group("Dashes")
@export var dashed: bool = false
#dash and gap lengths in border widths, evened out so each edge starts and ends with a dash
@export var dash_length: float = 3.0
@export var dash_gap: float = 2.0
@export_group("Shadow")
@export var shadow_color: Color = Color.TRANSPARENT
@export var shadow_offset: Vector2 = Vector2.ZERO
@export_group("Inset")
@export var inset_color: Color = Color.TRANSPARENT
@export var inset_width: int = 0

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if shadow_color.a > 0.0 and shadow_offset != Vector2.ZERO:
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + shadow_offset, rect.size), shadow_color)
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, bg_color)

	var inner: Rect2 = rect.grow(-border_width)
	if inset_color.a > 0.0 and inset_width > 0:
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.end.x - inset_width, inner.position.y, inset_width, inner.size.y), inset_color)
		RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(inner.position.x, inner.end.y - inset_width, inner.size.x, inset_width), inset_color)

	if border_width <= 0:
		return
	var width: float = border_width
	_draw_edge(to_canvas_item, rect.position, Vector2.RIGHT, rect.size.x, width)
	_draw_edge(to_canvas_item, Vector2(rect.position.x, rect.end.y - width), Vector2.RIGHT, rect.size.x, width)
	_draw_edge(to_canvas_item, rect.position + Vector2(0, width), Vector2.DOWN, rect.size.y - width * 2, width)
	_draw_edge(to_canvas_item, Vector2(rect.end.x - width, rect.position.y + width), Vector2.DOWN, rect.size.y - width * 2, width)

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
