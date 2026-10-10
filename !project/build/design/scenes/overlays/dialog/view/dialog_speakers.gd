class_name DialogSpeakers
extends Control

@export var anim_duration: float = 0.15

@onready var left_speaker: TextureRect = $LeftSpeaker
@onready var right_speaker: TextureRect = $RightSpeaker
@onready var left_name_plate: PanelContainer = $LeftNamePlate
@onready var right_name_plate: PanelContainer = $RightNamePlate
@onready var left_name_label: Label = $LeftNamePlate/Name
@onready var right_name_label: Label = $RightNamePlate/Name
@onready var name_font_size: int = left_name_label.get_theme_font_size("font_size")

func _ready() -> void:
	left_name_plate.resized.connect(_autosize_speaker_name.bind(left_name_plate, left_name_label))
	right_name_plate.resized.connect(_autosize_speaker_name.bind(right_name_plate, right_name_label))

	_autosize_speaker_name(left_name_plate, left_name_label)
	_autosize_speaker_name(right_name_plate, right_name_label)

#stretches name plates from the screen edges up to the dialog box sides
func set_dialogue_width(dialog_width: float) -> void:
	left_name_plate.offset_right = -dialog_width / 2.0
	right_name_plate.offset_left = dialog_width / 2.0

#shrinks the name font until the name fits inside its plate
func _autosize_speaker_name(name_plate: PanelContainer, name_label: Label) -> void:
	var name_plate_style: StyleBox = name_plate.get_theme_stylebox("panel")
	var outline_width: int = name_label.get_theme_constant("outline_size")
	var name_width_limit: float = name_plate.size.x - name_plate_style.get_minimum_size().x - outline_width
	var name_font: Font = name_label.get_theme_font("font")

	var fitted_font_size: int = name_font_size
	while fitted_font_size > 1 and name_font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_font_size).x > name_width_limit:
		fitted_font_size -= 1
	name_label.add_theme_font_size_override("font_size", fitted_font_size)

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
