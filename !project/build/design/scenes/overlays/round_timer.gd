class_name RoundTimerDisplay
extends Control

@onready var _label: Label = $TimeLabel

var _round_timer: Timer
var _update_timer: Timer

func _ready() -> void:
	_update_timer = Timer.new()
	_update_timer.wait_time = 1.0
	_update_timer.timeout.connect(_update_display)
	add_child(_update_timer)
	_update_timer.start()
	_update_display()

func set_round_timer(timer: Timer) -> void:
	_round_timer = timer
	_update_display()

#the bonus text slides in from off screen left along the time and, reaching the end of the numbers, bursts into the new time, sparks closing in
func implode_bonus_time(bonus_text: String) -> void:
	var time_text: String = _label.text
	var label_font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	var time_text_width: float = label_font.get_string_size(time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var char_width: float = time_text_width / time_text.length()
	var colon_index: int = time_text.find(":")
	var colon_left: float = (_label.size.x - time_text_width) / 2.0 + colon_index * char_width
	var time_text_right: float = (_label.size.x + time_text_width) / 2.0

	var bonus_label: Label = _label.duplicate() as Label
	bonus_label.text = bonus_text
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bonus_label.add_theme_color_override("font_color", Configs.BonusTime["text_color"])
	add_child(bonus_label)
	bonus_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bonus_label.size = Vector2(char_width * bonus_text.length(), _label.size.y)
	bonus_label.pivot_offset = bonus_label.size / 2.0

	#ends with its last character over the last digit, starts just past the left screen edge
	var overlap_position: Vector2 = _label.position + Vector2(time_text_right - bonus_label.size.x, 0.0)
	bonus_label.position = Vector2(-global_position.x - bonus_label.size.x, overlap_position.y)
	var seconds_length: int = time_text.length() - colon_index - 1
	var seconds_center: Vector2 = _label.position + Vector2(colon_left + char_width * (1.0 + seconds_length / 2.0), _label.size.y / 2.0)

	var burst_time: float = Configs.BonusTime["burst_time"]
	var implode_tween: Tween = bonus_label.create_tween()
	implode_tween.tween_property(bonus_label, "position", overlap_position, Configs.BonusTime["slide_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	implode_tween.tween_callback(_update_display)
	implode_tween.tween_callback(_converge_sparks.bind(seconds_center))
	implode_tween.tween_property(bonus_label, "scale", Vector2.ONE * Configs.BonusTime["burst_end_scale"], burst_time).set_ease(Tween.EASE_IN)
	implode_tween.parallel().tween_property(bonus_label, "modulate:a", 0.0, burst_time).set_ease(Tween.EASE_IN)
	implode_tween.finished.connect(bonus_label.queue_free)

#shows the new time at once while the old last digit grows red and fades over it, bursting sparks
func explode_last_digit() -> void:
	var old_time_text: String = _label.text
	_update_display()

	var label_font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	var time_text_width: float = label_font.get_string_size(old_time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var digit_width: float = time_text_width / old_time_text.length()
	var digit_left: float = (_label.size.x + time_text_width) / 2.0 - digit_width

	var digit_label: Label = _label.duplicate() as Label
	digit_label.text = old_time_text.right(1)
	digit_label.add_theme_color_override("font_color", Configs.SkipPenalty["digit_color"])
	add_child(digit_label)
	digit_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	digit_label.size = Vector2(digit_width, _label.size.y)
	digit_label.global_position = _label.global_position + Vector2(digit_left, 0.0)
	digit_label.pivot_offset = digit_label.size / 2.0

	var explode_time: float = Configs.SkipPenalty["explode_time"]
	var explode_tween: Tween = digit_label.create_tween().set_parallel()
	explode_tween.tween_property(digit_label, "scale", Vector2.ONE * Configs.SkipPenalty["digit_peak_scale"], explode_time).set_ease(Tween.EASE_OUT)
	explode_tween.tween_property(digit_label, "modulate:a", 0.0, explode_time).set_ease(Tween.EASE_IN)
	explode_tween.finished.connect(digit_label.queue_free)

	_burst_sparks(digit_label.global_position + digit_label.pivot_offset)

#one-shot spark burst at the given screen point, freed once the sparks die
func _burst_sparks(burst_position: Vector2) -> void:
	var spark_fade := Gradient.new()
	spark_fade.set_color(0, Configs.SkipPenalty["digit_color"])
	spark_fade.set_color(1, Color(Configs.SkipPenalty["digit_color"], 0.0))

	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = Configs.SkipPenalty["spark_count"]
	sparks.lifetime = Configs.SkipPenalty["explode_time"]
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = Configs.SkipPenalty["spark_speed"] / 2.0
	sparks.initial_velocity_max = Configs.SkipPenalty["spark_speed"]
	sparks.scale_amount_min = Configs.SkipPenalty["spark_size"]
	sparks.scale_amount_max = Configs.SkipPenalty["spark_size"]
	sparks.color_ramp = spark_fade
	sparks.finished.connect(sparks.queue_free)
	add_child(sparks)
	sparks.global_position = burst_position
	sparks.emitting = true

#one-shot sparks closing in from a ring onto the given point, freed once they arrive
func _converge_sparks(converge_position: Vector2) -> void:
	var spark_color: Color = Configs.BonusTime["text_color"]
	var spark_fade := Gradient.new()
	spark_fade.set_color(0, Color(spark_color, 0.0))
	spark_fade.set_color(1, spark_color)

	#from rest, this pull inward reaches the centre exactly as the sparks die
	var burst_time: float = Configs.BonusTime["burst_time"]
	var ring_radius: float = Configs.BonusTime["spark_ring_radius"]
	var inward_pull: float = -2.0 * ring_radius / (burst_time * burst_time)

	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = Configs.BonusTime["spark_count"]
	sparks.lifetime = burst_time
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	sparks.emission_sphere_radius = ring_radius
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 0.0
	sparks.initial_velocity_max = 0.0
	sparks.radial_accel_min = inward_pull
	sparks.radial_accel_max = inward_pull
	sparks.scale_amount_min = Configs.BonusTime["spark_size"]
	sparks.scale_amount_max = Configs.BonusTime["spark_size"]
	sparks.color_ramp = spark_fade
	sparks.finished.connect(sparks.queue_free)
	add_child(sparks)
	sparks.position = converge_position
	sparks.emitting = true

func _update_display() -> void:
	if not is_instance_valid(_label):
		return
	var seconds_left: int = ceili(_round_timer.time_left) if is_instance_valid(_round_timer) else ceili(Configs.Round.duration)
	var minutes: int = seconds_left / 60
	var seconds: int = seconds_left % 60
	_label.text = "%02d:%02d" % [minutes, seconds]
