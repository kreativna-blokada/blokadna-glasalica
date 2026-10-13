@tool
class_name SummaryScoreBar
extends Control

#segmented bar, one cell per answer: green for correct ones, red for the rest

@export var correct_color: Color = Color("#9DB565")
@export var wrong_color: Color = Color("#9B2C1C")
@export var line_color: Color = Color("#161616")
@export var shadow_color: Color = Color("#C9BFA5")
@export var border_width: float = 4.0
@export var tick_width: float = 3.0
@export var shadow_offset: Vector2 = Vector2(4, 4)

var _correct_count: int = 0
var _total_count: int = 0

func set_score(correct_count: int, total_count: int) -> void:
	_correct_count = correct_count
	_total_count = total_count
	queue_redraw()

func _draw() -> void:
	var bar: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(shadow_offset, size), shadow_color)
	draw_rect(bar, wrong_color)

	var inner: Rect2 = bar.grow(-border_width)
	if _total_count > 0:
		var cell_width: float = inner.size.x / _total_count
		draw_rect(Rect2(inner.position, Vector2(cell_width * _correct_count, inner.size.y)), correct_color)
		for i in range(1, _total_count):
			draw_rect(Rect2(inner.position.x + cell_width * i - tick_width, inner.position.y, tick_width, inner.size.y), line_color)

	draw_rect(bar.grow(-border_width / 2.0), line_color, false, border_width)
