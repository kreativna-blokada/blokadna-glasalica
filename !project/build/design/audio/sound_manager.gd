##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Plays the music loops, jingles and stingers over every screen
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
extends Node

#players taking turns on the stingers, so stingers close together do not cut each other off
const _STINGER_PLAYER_COUNT: int = 4

#private vars
var _music_player: AudioStreamPlayer
var _jingle_player: AudioStreamPlayer
var _stinger_players: Array[AudioStreamPlayer] = []
var _next_stinger_index: int = 0
#every music loop, jingle and stinger, loaded once and keyed by its path
var _loaded_streams: Dictionary[String, AudioStream] = {}
#path of the music loop playing or fading in, empty when none
var _music_path: String = ""
#path of the music loop starting once the jingle ends, empty when none
var _music_after_jingle_path: String = ""
var _music_fading_animation: Tween

#loads every stream and creates the music, jingle and stinger players
func _ready() -> void:
	for stream_path: String in Globals.MusicLoops.values() + Globals.SoundClips.values():
		_loaded_streams[stream_path] = load(stream_path)

	_music_player = _add_player()
	_jingle_player = _add_player()
	_jingle_player.finished.connect(_on_jingle_finished)
	for player_index: int in _STINGER_PLAYER_COUNT:
		_stinger_players.append(_add_player())

#signal AudioStreamPlayer.finished => the jingle is over, the music loop waiting for it starts
func _on_jingle_finished() -> void:
	if _music_after_jingle_path.is_empty(): return

	var waiting_music_path: String = _music_after_jingle_path
	_music_after_jingle_path = ""
	_switch_music(waiting_music_path)

#fades over to the music loop; the loop already playing keeps playing; while a jingle plays, the loop waits for it to end
func play_music(music_loop: Globals.Music) -> void:
	if _jingle_player.playing:
		_music_after_jingle_path = Globals.MusicLoops[music_loop]
		return

	_music_after_jingle_path = ""
	_switch_music(Globals.MusicLoops[music_loop])

#cuts the music and the jingle at once, without fading, so the screen's own sounds never play under them
func stop_music() -> void:
	_music_after_jingle_path = ""
	_jingle_player.stop()
	if _music_fading_animation: _music_fading_animation.kill()
	_music_player.stop()
	_music_path = ""

#fades the music out, plays the jingle, then starts the music loop once the jingle ends
func play_jingle(jingle_sound: Globals.Sound, following_music: Globals.Music) -> void:
	_switch_music("")
	_jingle_player.stream = _loaded_streams[Globals.SoundClips[jingle_sound]]
	_jingle_player.volume_db = Configs.Sound["clip_volume"]
	_jingle_player.play()
	_music_after_jingle_path = Globals.MusicLoops[following_music]

#plays the stinger on the next stinger player, over the music
func play_stinger(stinger_sound: Globals.Sound) -> void:
	var stinger_player: AudioStreamPlayer = _stinger_players[_next_stinger_index]
	_next_stinger_index = (_next_stinger_index + 1) % _stinger_players.size()
	stinger_player.stream = _loaded_streams[Globals.SoundClips[stinger_sound]]
	stinger_player.volume_db = Configs.Sound["clip_volume"]
	stinger_player.play()

#adds a player under this node
func _add_player() -> AudioStreamPlayer:
	var sound_player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(sound_player)
	return sound_player

#fades the playing loop out, then fades the next one in; an empty path only fades out
func _switch_music(next_music_path: String) -> void:
	if next_music_path == _music_path: return

	_music_path = next_music_path
	if _music_fading_animation: _music_fading_animation.kill()

	var fade_duration: float = Configs.Sound["music_fade"]
	_music_fading_animation = create_tween()
	if _music_player.playing:
		_music_fading_animation.tween_property(_music_player, "volume_db", Configs.Sound["silent_volume"], fade_duration)
	_music_fading_animation.tween_callback(_start_music.bind(next_music_path))
	if not next_music_path.is_empty():
		_music_fading_animation.tween_property(_music_player, "volume_db", Configs.Sound["music_volume"], fade_duration)

#stops the faded out loop and starts the next one silent, for the fade in; an empty path leaves it stopped
func _start_music(next_music_path: String) -> void:
	_music_player.stop()
	if next_music_path.is_empty(): return

	_music_player.stream = _loaded_streams[next_music_path]
	_music_player.volume_db = Configs.Sound["silent_volume"]
	_music_player.play()
