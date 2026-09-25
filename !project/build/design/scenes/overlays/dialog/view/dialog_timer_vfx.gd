class_name DialogTimerVfx
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var clock_hand: Control = $Container/ClockHand
	var clock_base: Control = $Container
	var hand_tween: Tween = create_tween().set_loops()
	hand_tween.tween_property(clock_hand, "rotation_degrees",360, 4.0).from_current()


	var base_tween: Tween = create_tween().set_loops()
	# Move 100 pixels to the right over 1 second
	base_tween.tween_property(self, "position:x", 16.0, 0.5).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Move back 100 pixels (to the left) over 1 second
	base_tween.chain().tween_property(self, "position:x", -16.0, 0.5).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
