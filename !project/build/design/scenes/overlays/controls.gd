class_name Controls
extends CanvasLayer

var _next_enabled_texture: Texture2D
var _next_disabled_texture: Texture2D

@onready var _next_button: TouchScreenButton = $Node/Next

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

func init(stage: Stage) -> void:
	stage.next_voter_availability_updated.connect(set_next_enabled)
	set_next_enabled(stage.is_next_voter_available())

func set_next_enabled(is_enabled: bool) -> void:
	_next_button.texture_normal = _next_enabled_texture if is_enabled else _next_disabled_texture
	_next_button.texture_pressed = _next_disabled_texture
