class_name CharacterDialogBase
extends Node

@export var textboxScalePx: Vector2i = Vector2(1200, 900)
@export var unveilSpeed: float = 30 # per second

var _unveilTimer: float = 1.0 / unveilSpeed
var _lastUnveiledCharIndex: int = 0
#false shows the smaller pre-zoom dialogue
var _is_zoomed_dialogue: bool = true

# 16 pixel padding for the actual borders of the dialog box
# and then some :D
const textMargin: Vector2 = Vector2(24, 24)

func initialize(textboxScale: Vector2i, is_zoomed_dialogue: bool) -> void:
	textboxScalePx = textboxScale
	_is_zoomed_dialogue = is_zoomed_dialogue

func set_tint(_tint: Color) -> void:
	pass

func set_text(dialog_descriptor: DialogDescriptor) -> void:
	pass

func _ready() -> void:
	pass

func reset_unveil() -> void:
	_lastUnveiledCharIndex = 0

func unveil_full_text(text: String) -> void:
	_lastUnveiledCharIndex = text.length()

func get_unveiled(text: String, delta: float) -> String:
	_unveilTimer -= delta
	if _unveilTimer <= 0:
		_unveilTimer = 1 / unveilSpeed
		_lastUnveiledCharIndex += 1
		if _lastUnveiledCharIndex > text.length():
			_lastUnveiledCharIndex = text.length()
			
	return text.substr(0, _lastUnveiledCharIndex)

#### gives the dialogue the pre-zoom font and darkens the box, re-using 153f7a2 - 60e239c
func apply_compact_look(text_label: RichTextLabel, box_background: CanvasItem) -> void:
	text_label.theme = load(Configs.DialogueZoom["compact_theme"])
	box_background.modulate = Configs.DialogueZoom["compact_box_tint"]

func apply_margins(node: Control, margin: Vector2) -> void:
	node.position += margin
	node.size -= margin * 2

# warn in debug builds when dialogue text is taller than its label and gets cut off
func warn_if_text_overflows(text_label: RichTextLabel) -> void:
	if OS.is_debug_build() and text_label.get_content_height() > text_label.size.y:
		push_warning("Dialogue text is cut off at the bottom: %s" % text_label.text)
