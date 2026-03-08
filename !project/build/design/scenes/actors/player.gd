class_name Player
extends Character

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)

func handle_input() -> void:
	if can_move():
		var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = direction * speed

func set_heading() -> void:
	if can_move():
		if velocity.x > 0:
			heading = Vector2.RIGHT
		elif velocity.x < 0:
			heading = Vector2.LEFT
