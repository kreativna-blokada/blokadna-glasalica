##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Gameplay configuration settings
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
extends Node

#GAMEPLAY
# ██████╗  █████╗ ███╗   ███╗███████╗██████╗ ██╗      █████╗ ██╗   ██╗
#██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝
#██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝██║     ███████║ ╚████╔╝
#██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔═══╝ ██║     ██╔══██║  ╚██╔╝
#╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║     ███████╗██║  ██║   ██║
# ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝

var Shake: Dictionary[String, Variant] = {
	#up/down movements required to start the game
	"shake_count": 3,
	#play button clicks required to start the game, fallback when the phone can't be shaken
	"click_count": 3,
	#ms w/o a shake before the counter resets
	"timeout": 1500,
	#m/s² along device y axis, above gravity (~9.8)
	"shake_threshold": 15.0,
	#px the text jumps per shake
	"jump_height": 120.0,
	#s for one jump, up and back to rest
	"jump_duration": 0.5,
	#s the jump sound takes to swell from silence at each play
	"sound_fade_in": 0.15,
	#s the jump sound takes to die out before its end
	"sound_fade_out": 0.15,
	#s the 3 stays on the button after the last click, before the start sequence
	"click_pause": 0.5,
	#s the play button is held to fill it and start the game, counting up like a click each click_count share of it
	"hold_duration": 1.5,
	#s a click takes to sweep the play button fill up to its next click_count share
	"click_fill_duration": 0.15,
	#px font size of the 3 on the button after the 1st, 2nd and 3rd click
	"click_font_sizes": [80, 100, 120],
	#s countdown digits 1, 2 and 3 each stay on screen after the last jump sound, before the game starts
	"digit_durations": [2.0, 2.0, 4.0],
	#countdown digits 1, 2 and 3 base alpha before each one fades in fully
	"digit_opacities": [0.64, 0.64, 0.75],
	#s each matrix text line stays on screen once the matrix rain opens, first one line then the other
	"init_line_duration": 4.8,
	#debug builds only: stretches all timing once the matrix rain opens (sound, phone, text, countdown); 2.0 = twice as slow
	"sequence_slowdown": 1.0,
}

var HandHint: Dictionary[String, Variant] = {
	#game starts (1 = the first game) on which the pointing hand shows how to move the ballot, never after the last one
	"play_numbers": [1, 2, 5, 8, 12, 16, 20, 25],
	#device file holding how many games this player has started
	"plays_record": "user://hint_plays.cfg",
}

var CardDrag: Dictionary[String, Variant] = {
	#px the finger moves up/down on the ballot box before the card follows it
	"drag_threshold": 30.0,
	#s the card takes to rise from where it was to the top of the slot once grabbed
	"snap_duration": 0.15,
	#px the card can be pushed down from its top resting point; the 5 rows share this depth equally
	"slot_depth": 320.0,
}

var MenuDifficulty: Dictionary[String, Variant] = {
	#ClickCounterLabel font size while the difficulty row is chosen, small enough for the longest difficulty text to fit the MenuOptionButton
	"font_size": 80,
	#s the arrows ignore further taps after switching the difficulty
	"tap_debounce": 0.1,
}

var Round: Dictionary[String, Variant] = {
	#s a run lasts before the score is submitted and the leaderboard opens
	"duration": 300.0,
	#s left on the round timer when the challenge music takes over for good
	"challenge_time": 30.0,
	#station number (Lamp is 1) from which the room voter brings in a new voter while nobody waits in the queue
	"queue_refill_station": 5,
	#s added to the round for every voter answered only with best answers at all stations
	"flawless_voter_bonus": 5.0,
	#s of flawless voter bonus a round can gain at most, so the round always ends
	"bonus_time_limit": 25.0,
}

var BonusTime: Dictionary[String, Variant] = {
	#colour of the bonus text rising into the round timer, and of its sparks
	"text_color": Color(0.35, 0.9, 0.4, 0.9),
	#s the bonus text slides in from off screen left until it reaches the end of the time
	"slide_time": 0.5,
	#s the bonus text shrinks and fades into the time, and the sparks close in
	"burst_time": 0.3,
	#bonus text scale at the end of the burst
	"burst_end_scale": 0.6,
	#sparks closing in onto the seconds
	"spark_count": 6,
	#px from the seconds the sparks start closing in from
	"spark_ring_radius": 40.0,
	#px side of a spark
	"spark_size": 4.0,
}

var DialogueScore: Dictionary[String, Variant] = {
	#s an answer screen ignores picks after it opens, so no answer can be given faster
	"answer_lock_time": 5.0,
	#s the answer screen stays locked after the player skips the line unveiling, cutting the lock short
	"skip_unlock_grace": 1.0,
	#s taken off the round timer whenever skipping the line cuts the lock short
	"skip_round_penalty": 1.0,
}

var SkipPenalty: Dictionary[String, Variant] = {
	#colour the old last digit of the round timer turns as it explodes, and of its sparks
	"digit_color": Color(0.9, 0.35, 0.3, 0.8),
	#old last digit scale at the end of the explosion
	"digit_peak_scale": 1.3,
	#s the old last digit grows and fades, and the sparks live
	"explode_time": 0.3,
	#sparks bursting from the old last digit
	"spark_count": 6,
	#px/s the fastest spark flies out at, the slowest at half
	"spark_speed": 120.0,
	#px side of a spark
	"spark_size": 4.0,
}

var AnswerLock: Dictionary[String, Variant] = {
	#wash over the part of a locked answer the colour has not filled yet
	"locked_wash_color": Color(0.0, 0.0, 0.0, 0.10),
	#answer background tint of a pick made during the lock, submitted the moment it unlocks
	"pending_answer_tint": Color(0.55, 0.85, 0.55, 1.0),
	#opacity of the padlock, drawn in the answer text colour, solid on a pending pick
	"padlock_opacity": 0.75,
	#px height of the padlock
	"padlock_height": 40.0,
	#px from the answer's right edge to the padlock centre
	"padlock_right_offset": 28.0,
	#s the padlock shackle takes to spring open on unlock
	"padlock_open_time": 0.15,
	#answer scale at the top of the unlock bounce
	"unlock_bounce_scale": 1.04,
	#answer brightness at the top of the unlock flash, 1 is unchanged
	"unlock_flash_brightness": 1.2,
	#s the unlock bounce and flash take to rise and settle each
	"unlock_pop_time": 0.12,
	#s the opened padlock fades out after the pop
	"padlock_fade_time": 0.25,
}

var Sound: Dictionary[String, Variant] = {
	#dB of the music loops
	"music_volume": -6.0,
	#dB of the jingles and stingers
	"clip_volume": -3.0,
	#s one music loop fades out, and the next one fades in again
	"music_fade": 0.4,
	#dB a fading music loop starts from or ends at
	"silent_volume": -40.0,
}

var ClassicalControllers: Dictionary[String, Variant] = {
	#on-screen buttons opacity for the inactive state
	"inactive_buttons_opacity": 0.35,
	#dialog answer background tint on Confirm submit
	"highlighted_answer_tint": Color(1.0, 0.85, 0.3, 1.0),
	#dialog opening grace period before the voter stops
	"dialog_opening_buffer": 0.5,
	#gold of the guide border shown around Select, then Initiate, until the first start, same as the name plate border
	"guide_border_color": Color(0.72, 0.62, 0.32, 1.0),
	#px width of the guide border
	"guide_border_width": 32,
	#px gap between the guided button and the guide border
	"guide_border_gap": 6,
	#px rounding of the guide border corners
	"guide_border_radius": 12,
	#seconds of one guide border pulse, fading out and back in; 0 keeps the border still
	"guide_border_pulse": 1.0,
	#lowest guide border opacity reached while pulsing
	"guide_border_faded_opacity": 0.05,
	#stations where the guide border pulses around Initiate the first time the room voter stops there
	"initiate_guide_stations": [1, 2],
}

#round holes the dialog dim leaves over the on-screen buttons
var Spotlights: Dictionary[String, Variant] = {
	#px a hole reaches past its button's edge
	"spotlight_padding": 16.0,
	#px over which a hole's edge fades into the full dim
	"spotlight_softness": 16.0,
}

#HUD stop indicators tinted by the queue waiting before the stop
var BottleneckIndicators: Dictionary[String, Variant] = {
	#subtle but distinguishable red tint when the queue reaches the alert threshold
	"alert_indicator_color": Color(1.0, 0.78, 0.78, 1),
	#subtle but distinguishable yellow tint when the queue reaches the warning threshold
	"warning_indicator_color": Color(1.0, 0.96, 0.72, 1),
}

#dialogue without zoom, re-using 153f7a2 - 60e239c
var DialogueZoom: Dictionary[String, Variant] = {
	#regular font at 29 for the dialogue and answer text
	"compact_theme": "res://!project/art/UI/DialogBox/dialog_box_compact.tres",
	#dialog box background tint darkening it
	"compact_box_tint": Color(0.9647059, 0.9372549, 0.8627451, 1),
	#px the single line dialogue text runs past the box on the right and bottom
	"compact_text_overhang": 24.0,
	#answer box height limit in text lines
	"compact_answer_max_lines": 2,
	#px between the zoomed answer text and its box border, above and below
	"answer_text_padding": 16.0,
}

var Leaderboard: Dictionary[String, Variant] = {
	#debug firebase database endpoint, public on purpose; its rules get locked once the game is public
	"debug_endpoint": "https://glasalica-default-rtdb.europe-west1.firebasedatabase.app/",
	#number of best scores fetched for the leaderboard
	"top_count": 10,
	#must match the length limit in the database rules
	"username_length": 20,
	#s before a leaderboard request gives up
	"request_timeout": 10.0,
	#number of days, today included, the daily tab lets the player pick
	"daily_history_days": 30,
	#number of calendar weeks, this week included, the weekly tab lets the player pick
	"weekly_history_weeks": 12,
	#h added to UTC to pick the day a run's daily leaderboard is stored under; fixed, so in summer time the day
	#turns at 01:00 local; must match the 3600000 ms in the database rules
	"day_utc_offset": 1,
}

var IdReveal: Dictionary[String, Variant] = {
	#letters per second the player id unveils at, same as the dialogue unveilSpeed
	"unveil_speed": 30.0,
}

#ENTITY
#███████╗███╗   ██╗████████╗██╗████████╗██╗   ██╗
#██╔════╝████╗  ██║╚══██╔══╝██║╚══██╔══╝╚██╗ ██╔╝
#█████╗  ██╔██╗ ██║   ██║   ██║   ██║    ╚████╔╝
#██╔══╝  ██║╚██╗██║   ██║   ██║   ██║     ╚██╔╝
#███████╗██║ ╚████║   ██║   ██║   ██║      ██║
#╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝   ╚═╝      ╚═╝

enum Entity {
	Voter
}

var EntityProperties: Dictionary[Variant, Variant] = {
	Entity.Voter: {
		"speed": 200,
		"lives": 0
	}
}
