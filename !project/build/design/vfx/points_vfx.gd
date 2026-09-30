class_name PointsVfx
extends Node2D

@export var duration: float = 0.6
@export var jump_height: float = 60.0
@export var horizontal_drift: float = 50.0
@export var rotation_amount: float = 0.5  # radians
@export var fade_out: bool = true

@onready var label: RichTextLabel = $Label

func setup(text: String, color: Color) -> void:
	label.text = text
	label.modulate = color

func play() -> void:
	# Randomize direction slightly so repeated popups don't look identical
	var drift := randf_range(-horizontal_drift, horizontal_drift)
	var rot := randf_range(-rotation_amount, rotation_amount)

	var start_pos := position
	var target_pos := start_pos + Vector2(drift, -jump_height)

	label.scale = Vector2(0.5, 0.5)
	label.rotation = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Pop-in scale
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.3)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), duration * 0.2)

	# Translation "jump"
	tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Rotation "wobble"
	tween.tween_property(label, "rotation", rot, duration).set_trans(Tween.TRANS_SINE)

	if fade_out:
		tween.tween_property(label, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)

	tween.chain().tween_callback(queue_free)
