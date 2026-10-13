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

#centre of the time text on screen, where the bonus time popup shows
func get_time_center() -> Vector2:
	return _label.get_global_rect().get_center()

func _update_display() -> void:
	if not is_instance_valid(_label):
		return
	var seconds_left: int = ceili(_round_timer.time_left) if is_instance_valid(_round_timer) else ceili(Configs.Round.duration)
	var minutes: int = seconds_left / 60
	var seconds: int = seconds_left % 60
	_label.text = "%02d:%02d" % [minutes, seconds]
