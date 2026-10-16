@tool
class_name SummaryIcon
extends Control

#square-capped stroke icon, scaled from its design box to the control's size

enum Shape {CHECK, CROSS, CHEVRON}

#strokes per shape in design box units, each a polyline
const STROKES: Dictionary[Shape, Array] = {
	Shape.CHECK: [[Vector2(3, 11), Vector2(9, 17), Vector2(19, 5)]],
	Shape.CROSS: [[Vector2(4, 4), Vector2(18, 18)], [Vector2(18, 4), Vector2(4, 18)]],
	Shape.CHEVRON: [[Vector2(4, 9), Vector2(14, 19), Vector2(24, 9)]],
}
const BOX_SIZES: Dictionary[Shape, float] = {
	Shape.CHECK: 22.0,
	Shape.CROSS: 22.0,
	Shape.CHEVRON: 28.0,
}

@export var shape: Shape = Shape.CHECK:
	set(value):
		shape = value
		queue_redraw()
@export var color: Color = Color.BLACK:
	set(value):
		color = value
		queue_redraw()
#stroke width in design box units
@export var stroke_width: float = 4.0:
	set(value):
		stroke_width = value
		queue_redraw()
#turns the drawing around the centre; containers reset the control's own rotation on layout
@export var turn_degrees: float = 0.0:
	set(value):
		turn_degrees = value
		queue_redraw()

func _draw() -> void:
	var box_scale: float = minf(size.x, size.y) / BOX_SIZES[shape]
	var origin: Vector2 = (size - Vector2.ONE * BOX_SIZES[shape] * box_scale) / 2.0
	var width: float = stroke_width * box_scale
	draw_set_transform(size / 2.0, deg_to_rad(turn_degrees))
	for stroke: Array in STROKES[shape]:
		var points: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in stroke:
			points.append(origin + point * box_scale - size / 2.0)
		#square caps: both ends reach half a stroke past their point
		points[0] += (points[0] - points[1]).normalized() * width / 2.0
		var last: int = points.size() - 1
		points[last] += (points[last] - points[last - 1]).normalized() * width / 2.0
		draw_polyline(points, color, width, true)
