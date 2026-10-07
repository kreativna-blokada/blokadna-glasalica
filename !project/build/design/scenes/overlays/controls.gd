class_name Controls
extends CanvasLayer

var _next_enabled_texture: Texture2D
var _next_disabled_texture: Texture2D

@onready var _next_button: TouchScreenButton = $Node/Next
@onready var _classic_buttons: Array[TouchScreenButton] = [$Validation/Correct, $Validation/Incorrect, $Selection/Select, $Selection/Initiate]

func _ready() -> void:
	_next_enabled_texture = _next_button.texture_normal
	_next_disabled_texture = _next_button.texture_pressed
	set_next_enabled(false)

#on-screen buttons for classic controls, the next button for screen controls
func init(stage: Stage, controller_type: Globals.ControllerType) -> void:
	var is_classic: bool = controller_type == Globals.ControllerType.Classic
	for classic_button in _classic_buttons:
		classic_button.visible = is_classic
	_next_button.visible = not is_classic

	stage.next_voter_availability_updated.connect(set_next_enabled)
	set_next_enabled(stage.is_next_voter_available())

func set_next_enabled(is_enabled: bool) -> void:
	_next_button.texture_normal = _next_enabled_texture if is_enabled else _next_disabled_texture
	_next_button.texture_pressed = _next_disabled_texture
