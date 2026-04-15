##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Scenery elements controller
#maintainer      : Zeljko Vulovic
#version         : 1.0
#===============================================================================
extends Node2D
@export_group("Gameplay Sounds")
@export var loop_sound : AudioStream

@onready var sound_player: AudioStreamPlayer = $Ambiente

func _ready() -> void:
	_init_sound()
	_loop_sound()

func _process(_delta: float) -> void:
	_loop_sound()

func _init_sound() -> void:
	if loop_sound:
		#initialises the audio stream
		sound_player.stream = loop_sound
		#sets audio to loop based on format
		if loop_sound is AudioStreamMP3:
			loop_sound.loop = true
		elif loop_sound is AudioStreamWAV:
			loop_sound.loop_mode = AudioStreamWAV.LOOP_FORWARD

func _loop_sound() -> void:
	if not loop_sound: return

	var game: Node = get_tree().current_scene
	if game and "stop_sounds" in game:
		var is_playing : bool = game.stop_sounds
		if sound_player.playing != is_playing:
			if is_playing:
				sound_player.play()
			else:
				sound_player.stop()

func _on_entry_body_entered(_body: Node2D) -> void:
	$Setup/Entry.visible = false

func _on_entry_body_exited(_body: Node2D) -> void:
	$Setup/Entry.visible = true

func _on_exit_body_entered(_body: Node2D) -> void:
	$Setup/Exit.visible = false

func _on_exit_body_exited(_body: Node2D) -> void:
	$Setup/Exit.visible = true
