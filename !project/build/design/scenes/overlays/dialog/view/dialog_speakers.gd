class_name DialogSpeakers
extends Control

@export var anim_duration: float = 0.15

@onready var left_speaker: TextureRect = $LeftSpeaker
@onready var right_speaker: TextureRect = $RightSpeaker

func initialize(speaker: DialogDescriptor.Speaker) -> void:
	match speaker:
		DialogDescriptor.Speaker.LEFT:
			_change_instant(left_speaker,true)
			_change_instant(right_speaker,false)
		DialogDescriptor.Speaker.RIGHT:
			_change_instant(left_speaker,false)
			_change_instant(right_speaker,true)
	

func set_active_speaker(speaker: DialogDescriptor.Speaker) -> void:
	match speaker:
		DialogDescriptor.Speaker.LEFT:
			_transition(left_speaker, anim_duration, true)
			_transition(right_speaker, anim_duration, false)
		DialogDescriptor.Speaker.RIGHT:
			_transition(left_speaker, anim_duration, false)
			_transition(right_speaker, anim_duration, true)

func _transition(speaker: Control, duration: float, state: bool) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	
	var color: Color = Color.DIM_GRAY 
	var target_scale := Vector2(0.85, 0.85)
	if state:
		color = Color.WHITE
		target_scale = Vector2(1,1)
		

	tween.set_parallel(true)
	tween.tween_property(speaker, "modulate", color, duration).from_current()
	tween.tween_property(speaker, "scale", target_scale, duration).from_current()

func _change_instant(speaker: Control, state: bool) -> void:
	var color: Color = Color.DIM_GRAY
	var target_scale := Vector2(0.85, 0.85)
	if state:
		color = Color.WHITE
		target_scale = Vector2(1,1)

	speaker.modulate = color
	speaker.scale = target_scale
