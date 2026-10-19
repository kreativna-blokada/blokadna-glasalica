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
#where each music loop left off, so every loop picks up there when it comes back; cleared when the music stops
var _music_positions: Dictionary[String, float] = {}
var _music_fading_animation: Tween

#loads every stream and creates the music, jingle and stinger players
func _ready() -> void:
	for stream_path: String in Globals.MusicLoops.values() + Globals.SoundClips.values():
		_loaded_streams[stream_path] = load(stream_path)

	_music_player = _add_player()
	#the web plays samples by default, decoding the whole loop and copying it again on every play, loop and unpause
	_music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
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
	_music_positions.clear()

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

#stops the faded out loop where it is, then starts the next one silent from where it left off, for the fade in; an empty path leaves it stopped
func _start_music(next_music_path: String) -> void:
	#the same loop coming back before it stopped keeps playing, only fading back in
	if _music_player.playing and _music_player.stream.resource_path == next_music_path: return

	if _music_player.playing:
		_music_positions[_music_player.stream.resource_path] = _get_loop_position(_music_player)
	_music_player.stop()
	if next_music_path.is_empty(): return

	_music_player.stream = _loaded_streams[next_music_path]
	_music_player.volume_db = Configs.Sound["silent_volume"]
	_music_player.play(_music_positions.get(next_music_path, 0.0))

#the playback position wrapped into the loop, a guard should the music go back to samples; a web sample reports the time played
#since its start offset, past the loop end, and resuming from there ends the sample at once, restarting it over and over;
#the wrap starts again from the loop offset, streams without a length keep their position
func _get_loop_position(sound_player: AudioStreamPlayer) -> float:
	var playback_position: float = sound_player.get_playback_position()
	var loop_length: float = sound_player.stream.get_length()
	if loop_length <= 0.0 or playback_position < loop_length: return playback_position

	#only Ogg and MP3 streams have a loop offset
	var stream_loop_offset: Variant = sound_player.stream.get("loop_offset")
	var loop_offset: float = stream_loop_offset if stream_loop_offset != null else 0.0
	if loop_offset >= loop_length: return 0.0
	return loop_offset + fmod(playback_position - loop_offset, loop_length - loop_offset)
