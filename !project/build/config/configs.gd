##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Gameplay configuration settings
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
extends Node


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
	#s the 3 stays on the button after the last click, before the start sequence
	"click_pause": 0.5,
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

var MenuHint: Dictionary[String, Variant] = {
	#InfoLabel anchor height (0 = screen top, 1 = bottom) while the team row is chosen, centered between the SloganLabel bottom and the WebVersionBox top
	"team_hint_anchor": 0.589,
	#InfoLabel font size while the team row is chosen, smaller so the long team text fits
	"team_font_size": 48,
}

var MenuDifficulty: Dictionary[String, Variant] = {
	#ClickCounterLabel font size while the difficulty row is chosen, small enough for the longest difficulty text to fit the MenuOptionButton
	"font_size": 52,
	#s the arrows ignore further taps after switching the difficulty
	"tap_debounce": 0.1,
}

var Round: Dictionary[String, Variant] = {
	#s a run lasts before the score is submitted and the leaderboard opens
	"duration": 300.0,
	#s left on the round timer when the challenge music takes over for good
	"challenge_time": 30.0,
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
