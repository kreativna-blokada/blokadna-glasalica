class_name DialogSpeakers
extends Control

@export var anim_duration: float = 0.15

#outline brought around the plate of the answering speaker, drawn in the colour of its name at full brightness
const NAME_PLATE_OUTLINE_WIDTH: int = 4
#glow fading out beyond the outline, in rings of the ring width, starting at the glow strength
const NAME_PLATE_GLOW_RINGS: int = 8
const NAME_PLATE_GLOW_RING_WIDTH: int = 2
const NAME_PLATE_GLOW_STRENGTH: float = 0.5
#sliding scanlines drawn over the speaker answering
const SCANLINE_SHADER: VisualShader = preload("res://!project/art/shaders/scanline.tres")

@onready var left_speaker: TextureRect = $LeftSpeaker
@onready var right_speaker: TextureRect = $RightSpeaker
@onready var left_name_plate: PanelContainer = $LeftNamePlate
@onready var right_name_plate: PanelContainer = $RightNamePlate
@onready var left_name_label: Label = $LeftNamePlate/Name
@onready var right_name_label: Label = $RightNamePlate/Name
@onready var name_font_size: int = left_name_label.get_theme_font_size("font_size")

#outline around each name plate and how visible it is, from 0 for the one talking to 1 for the one answering
var _name_plate_outline_style: StyleBoxFlat
var _name_plate_outline_alphas: Dictionary[PanelContainer, float] = {}
var _scanline_material: ShaderMaterial

func _ready() -> void:
	left_name_plate.resized.connect(_autosize_speaker_name.bind(left_name_plate, left_name_label))
	right_name_plate.resized.connect(_autosize_speaker_name.bind(right_name_plate, right_name_label))

	_autosize_speaker_name(left_name_plate, left_name_label)
	_autosize_speaker_name(right_name_plate, right_name_label)

	_name_plate_outline_style = _create_name_plate_outline_style()
	_scanline_material = ShaderMaterial.new()
	_scanline_material.shader = SCANLINE_SHADER
	left_name_plate.draw.connect(_draw_name_plate_outline.bind(left_name_plate, left_name_label))
	right_name_plate.draw.connect(_draw_name_plate_outline.bind(right_name_plate, right_name_label))

#hollow rounded frame following the plate corners, reshaped for the outline and each glow ring
func _create_name_plate_outline_style() -> StyleBoxFlat:
	var outline_style := StyleBoxFlat.new()
	outline_style.draw_center = false
	return outline_style

#draws the glow and then the outline around the plate in the bright name colour, as visible as its speaker is answering
func _draw_name_plate_outline(name_plate: PanelContainer, name_label: Label) -> void:
	var outline_alpha: float = _name_plate_outline_alphas.get(name_plate, 0.0)
	if outline_alpha <= 0.0:
		return
	var name_color: Color = name_label.get_theme_color("font_color")
	var outline_color := Color.from_hsv(name_color.h, name_color.s, 1.0)

	for glow_ring in range(NAME_PLATE_GLOW_RINGS, 0, -1):
		var glow_alpha: float = NAME_PLATE_GLOW_STRENGTH * (1.0 - float(glow_ring - 1) / NAME_PLATE_GLOW_RINGS)
		_draw_name_plate_ring(name_plate, NAME_PLATE_OUTLINE_WIDTH + glow_ring * NAME_PLATE_GLOW_RING_WIDTH, NAME_PLATE_GLOW_RING_WIDTH, Color(outline_color, glow_alpha * outline_alpha))
	_draw_name_plate_ring(name_plate, NAME_PLATE_OUTLINE_WIDTH, NAME_PLATE_OUTLINE_WIDTH, Color(outline_color, outline_alpha))

#draws one rounded ring of the given width, its outer edge the given distance outside the plate
func _draw_name_plate_ring(name_plate: PanelContainer, ring_distance: int, ring_width: int, ring_color: Color) -> void:
	var name_plate_style: StyleBoxFlat = name_plate.get_theme_stylebox("panel")
	_name_plate_outline_style.set_border_width_all(ring_width)
	_name_plate_outline_style.set_corner_radius_all(name_plate_style.corner_radius_top_left + ring_distance)
	_name_plate_outline_style.border_color = ring_color
	name_plate.draw_style_box(_name_plate_outline_style, Rect2(Vector2.ZERO, name_plate.size).grow(ring_distance))

#sets how visible the plate outline is and redraws the plate
func _set_name_plate_outline_alpha(outline_alpha: float, name_plate: PanelContainer) -> void:
	_name_plate_outline_alphas[name_plate] = outline_alpha
	name_plate.queue_redraw()

#puts the staff bust on the left and the voter bust on the right, all busts are drawn facing left so the left one is mirrored in the scene
func set_portraits(left_portrait: Texture2D, right_portrait: Texture2D) -> void:
	left_speaker.texture = left_portrait
	right_speaker.texture = right_portrait

#stretches name plates from the screen edges up to the dialog box sides, with each bust centred over its plate
func set_dialogue_width(dialog_width: float) -> void:
	left_name_plate.offset_right = -dialog_width / 2.0
	right_name_plate.offset_left = dialog_width / 2.0

	_center_speaker_over_name_plate(left_speaker, -dialog_width / 4.0)
	_center_speaker_over_name_plate(right_speaker, dialog_width / 4.0)

#places the bust centre the given px off its screen quarter line, where the centre of its plate sits
func _center_speaker_over_name_plate(speaker: TextureRect, name_plate_center_offset: float) -> void:
	var speaker_half_width: float = speaker.size.x / 2.0
	speaker.offset_left = name_plate_center_offset - speaker_half_width
	speaker.offset_right = name_plate_center_offset + speaker_half_width

#fills each name plate with the dialogue colour its speaker talks in
func set_name_plate_colors(left_speaker_color: Color, right_speaker_color: Color, box_tint: Color) -> void:
	_fill_name_plate(left_name_plate, left_speaker_color, box_tint)
	_fill_name_plate(right_name_plate, right_speaker_color, box_tint)

#gives the plate its own copy of the shared style, filled like the sentence box
func _fill_name_plate(name_plate: PanelContainer, speaker_color: Color, box_tint: Color) -> void:
	var name_plate_style: StyleBoxFlat = name_plate.get_theme_stylebox("panel").duplicate()
	name_plate_style.bg_color = speaker_color * box_tint
	name_plate.add_theme_stylebox_override("panel", name_plate_style)

#prints each name in the text colour of its speaker, shaded for its plate like the sentence for its box
func set_name_colors(left_text_color: Color, right_text_color: Color) -> void:
	DialogColors.apply_text_colors(left_name_label, left_text_color, left_name_plate.get_theme_stylebox("panel").bg_color)
	DialogColors.apply_text_colors(right_name_label, right_text_color, right_name_plate.get_theme_stylebox("panel").bg_color)

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
			_change_instant(left_speaker, left_name_plate, true)
			_change_instant(right_speaker, right_name_plate, false)
		DialogDescriptor.Speaker.RIGHT:
			_change_instant(left_speaker, left_name_plate, false)
			_change_instant(right_speaker, right_name_plate, true)

func set_active_speaker(speaker: DialogDescriptor.Speaker) -> void:
	match speaker:
		DialogDescriptor.Speaker.LEFT:
			_transition(left_speaker, left_name_plate, anim_duration, true)
			_transition(right_speaker, right_name_plate, anim_duration, false)
		DialogDescriptor.Speaker.RIGHT:
			_transition(left_speaker, left_name_plate, anim_duration, false)
			_transition(right_speaker, right_name_plate, anim_duration, true)

#grows or shrinks the speaker at full brightness, scanlining the one answering, while its name plate stays lit, outlining the plate of the one answering
func _transition(speaker: Control, name_plate: PanelContainer, duration: float, is_talking: bool) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)

	var target_scale := Vector2(0.85, 0.85)
	if is_talking:
		target_scale = Vector2(1,1)

	speaker.material = null if is_talking else _scanline_material

	tween.set_parallel(true)
	tween.tween_property(speaker, "modulate", Color.WHITE, duration).from_current()
	tween.tween_property(speaker, "scale", target_scale, duration).from_current()
	tween.tween_method(_set_name_plate_outline_alpha.bind(name_plate), _name_plate_outline_alphas.get(name_plate, 0.0), 0.0 if is_talking else 1.0, duration)

#shows the speaker at once at full brightness, scanlining the one answering, while its name plate stays lit, outlining the plate of the one answering
func _change_instant(speaker: Control, name_plate: PanelContainer, is_talking: bool) -> void:
	var target_scale := Vector2(0.85, 0.85)
	if is_talking:
		target_scale = Vector2(1,1)

	speaker.modulate = Color.WHITE
	speaker.scale = target_scale
	speaker.material = null if is_talking else _scanline_material
	_set_name_plate_outline_alpha(0.0 if is_talking else 1.0, name_plate)
