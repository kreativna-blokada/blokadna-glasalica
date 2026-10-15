##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Global custom signals container
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
extends Node

#emitted when the application should be closed
@warning_ignore("unused_signal")
signal game_close_requested

#emitted when the intro text should be opened again during the game
@warning_ignore("unused_signal")
signal help_requested

#emitted when the days holding scores for fetch_key are known; run days are newest first
@warning_ignore("unused_signal")
signal run_days_fetched(fetch_key: String, fetch_succeeded: bool, run_days: Array[int])

#emitted when the player's own best score for fetch_key is known; standing is {username, score}, or empty without a score there
@warning_ignore("unused_signal")
signal player_standing_fetched(fetch_key: String, fetch_succeeded: bool, standing: Dictionary)

#emitted when the leaderboard fetch for fetch_key finishes; the best entries {player_id, username, score}, best first
@warning_ignore("unused_signal")
signal ranks_fetched(fetch_key: String, fetch_succeeded: bool, rank_entries: Array[Dictionary])

#emitted when a score submission finishes; Stored means the database kept a higher score
@warning_ignore("unused_signal")
signal score_submitted(submit_result: Globals.ScoreSubmit)

#emitted when the database gives the player the username and it is stored on this device
@warning_ignore("unused_signal")
signal user_saved(saved_username: String)

#emitted when the database does not give the player the username; Taken means another player has it
@warning_ignore("unused_signal")
signal user_refused(refuse_reason: Globals.NameRefuse)

#emitted when menu is selected; the action is not defined yet
@warning_ignore("unused_signal")
signal menu_option_selected(menu_option: Globals.MainMenu)
