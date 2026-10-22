##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Shows the best scores by tab and period, only periods holding scores, with the player's own row centered
#maintainer      : Zeljko
#version         : 2.0
#===============================================================================
class_name LeaderboardScreen
extends Control

#one day, week or the whole season a tab can show; run days are the days holding scores, none for the whole season
class BoardPeriod:
	var key: String
	var top_caption: String
	var dates_caption: String
	var run_days: Array[int] = []

	func _init(period_key: String, period_top_caption: String, period_dates_caption: String) -> void:
		key = period_key
		top_caption = period_top_caption
		dates_caption = period_dates_caption

const PODIUM_ROW_SCENE: PackedScene = preload("res://!project/build/design/scenes/screens/leaderboard/podium_row.tscn")
const RANK_ROW_SCENE: PackedScene = preload("res://!project/build/design/scenes/screens/leaderboard/rank_row.tscn")

const PODIUM_SIZE: int = 3
const DISABLED_ARROW_ALPHA: float = 0.3
#s the list takes to glide to the player's row when the rank chip is tapped
const CENTER_SCROLL_DURATION: float = 0.35
#s a submit note stays above the back button
const SUBMIT_NOTE_DURATION: float = 2.0
const NOTE_ERROR_COLOR: Color = Color(0.478431, 0.121569, 0.0705882, 1)
#s the snackbar stays up, fades included, and s each of its fades takes
const SNACKBAR_DURATION: float = 4.0
const SNACKBAR_FADE_DURATION: float = 0.2
const TOTAL_PERIOD_KEY: String = "total"
const DAY_PERIOD_KEY: String = "day_%d"
const WEEK_PERIOD_KEY: String = "week_%d"
const DAYS_PER_WEEK: int = 7
#fetch key sent to LeaderboardManager: the period key and the fetch generation
const FETCH_KEY: String = "%s#%d"
const GAP_FONT_SIZE: int = 30
const GAP_FONT_COLOR: Color = Color(0.419608, 0.372549, 0.333333, 1)
const RUN_DAYS_FETCH_KEY: String = "run_days"

#rank chip style and text color for the 1st, 2nd and 3rd place; lower ranks keep the chip's own purple
@export var podium_chip_styles: Array[StyleBox] = []
@export var podium_chip_text_color: Color = Color.BLACK
@export var gap_font: Font

#private vars
var _run_points: int = LeaderboardManager.NO_RUN_POINTS_PENDING
var _is_submitting: bool = false
var _selected_board: Globals.ScoreBoard = Globals.ScoreBoard.Daily
#periods of each tab, latest first
var _board_periods: Dictionary[Globals.ScoreBoard, Array] = {}
var _period_indexes: Dictionary[Globals.ScoreBoard, int] = {
	Globals.ScoreBoard.Daily: 0,
	Globals.ScoreBoard.Weekly: 0,
	Globals.ScoreBoard.Total: 0,
}
#days and weeks are known once the days holding scores arrive; until then their tabs show this status
var _run_days_status: String = Literals.BOARD_LOADING_MESSAGE
#fetched best entries and the player's own standing below them, by period key, so stepping back to a period needs no new fetch
var _period_entries: Dictionary[String, Array] = {}
var _period_standings: Dictionary[String, Dictionary] = {}
var _fetching_entries: Dictionary[String, bool] = {}
var _fetching_standings: Dictionary[String, bool] = {}
#raised whenever the fetched entries go stale, so answers to older fetches are dropped
var _fetch_generation: int = 0
var _own_row: ScoreRow = null
var _scroll_tween: Tween = null
var _note_tween: Tween = null
var _snackbar_tween: Tween = null
#the rank chip's purple look from the scene, put back after a podium rank
var _own_chip_style: StyleBox = null
var _own_chip_text_color: Color = Color.BLACK
#most players above the player each tab downloads to count the rank below the best scores
var _rank_count_caps: Dictionary[Globals.ScoreBoard, int] = {
	Globals.ScoreBoard.Daily: Configs.Leaderboard.daily_rank_count_cap,
	Globals.ScoreBoard.Weekly: Configs.Leaderboard.weekly_rank_count_cap,
	Globals.ScoreBoard.Total: Configs.Leaderboard.total_rank_count_cap,
}

#onready vars
@onready var _title_label: Label = %TitleLabel
@onready var _rank_chip: PanelContainer = %RankChip
@onready var _chip_rank_label: Label = %ChipRankLabel
@onready var _no_result_chip: PanelContainer = %NoResultChip
@onready var _no_result_label: Label = %NoResultLabel
@onready var _rewards_button: Button = %RewardsButton
@onready var _board_tabs: Dictionary[Globals.ScoreBoard, Button] = {
	Globals.ScoreBoard.Daily: %DailyTab,
	Globals.ScoreBoard.Weekly: %WeeklyTab,
	Globals.ScoreBoard.Total: %TotalTab,
}
@onready var _period_stepper: HBoxContainer = %PeriodStepper
@onready var _older_button: Button = %OlderButton
@onready var _newer_button: Button = %NewerButton
@onready var _period_top_label: Label = %PeriodTopLabel
@onready var _period_dates_label: Label = %PeriodDatesLabel
@onready var _list_layout: VBoxContainer = %ListLayout
@onready var _podium_rows: VBoxContainer = %PodiumRows
@onready var _rest_scroll: ScrollContainer = %RestScroll
@onready var _rest_margin: MarginContainer = %RestMargin
@onready var _rest_rows: VBoxContainer = %RestRows
@onready var _board_status_label: Label = %BoardStatusLabel
@onready var _submit_note_label: Label = %SubmitNoteLabel
@onready var _snackbar: PanelContainer = %Snackbar
@onready var _snackbar_label: Label = %SnackbarLabel
@onready var _back_button: Button = %BackButton
@onready var _rewards_screen: RewardsScreen = %RewardsScreen

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_title_label.text = Literals.BOARD_TITLE
	_rewards_button.text = Literals.BOARD_REWARDS
	_back_button.text = Literals.BOARD_BACK
	_own_chip_style = _rank_chip.get_theme_stylebox("panel")
	_own_chip_text_color = _chip_rank_label.get_theme_color("font_color")
	for score_board in _board_tabs:
		_board_tabs[score_board].text = Literals.BOARD_TAB_CAPTIONS[score_board]
		_board_tabs[score_board].pressed.connect(_on_board_tab_pressed.bind(score_board))

	_older_button.pressed.connect(_on_period_arrow_pressed.bind(1))
	_newer_button.pressed.connect(_on_period_arrow_pressed.bind(-1))
	_rank_chip.gui_input.connect(_on_rank_chip_input)
	_rewards_button.pressed.connect(_on_rewards_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	Signals.run_days_fetched.connect(_on_run_days_fetched)
	Signals.ranks_fetched.connect(_on_ranks_fetched)
	Signals.player_standing_fetched.connect(_on_player_standing_fetched)
	Signals.score_submitted.connect(_on_score_submitted)

	_board_periods[Globals.ScoreBoard.Total] = [BoardPeriod.new(TOTAL_PERIOD_KEY, Literals.TOTAL_CAPTION, Literals.TOTAL_DATES_CAPTION)]
	_board_tabs[_selected_board].set_pressed_no_signal(true)

	#the name step's run score lost to a higher best is told here, once the board is up
	var declined_points: int = LeaderboardManager.take_declined_points()
	if declined_points != LeaderboardManager.NO_RUN_POINTS_PENDING:
		_show_snackbar(Literals.SCORE_HIGHER_MESSAGE % DialogScoreCalculator.format_points(declined_points))

	_run_points = LeaderboardManager.get_run_points()
	if _run_points != LeaderboardManager.NO_RUN_POINTS_PENDING and not GameManager.get_game_descriptor().is_challenge():
		_show_learning_points()
	if not LeaderboardManager.is_enabled():
		_show_selected_period()
		return

	#a run score still waiting, e.g. after a failed submit, goes out once the player has a name
	_run_points = LeaderboardManager.get_run_points()
	if _run_points != LeaderboardManager.NO_RUN_POINTS_PENDING and LeaderboardManager.is_valid_username(LeaderboardManager.get_username()):
		_is_submitting = true
		LeaderboardManager.submit_score(_run_points)

	_show_selected_period()
	LeaderboardManager.fetch_run_days(FETCH_KEY % [RUN_DAYS_FETCH_KEY, _fetch_generation])

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#fills the day and week periods from the days holding scores, latest first, keeping each tab on the period it showed
func _build_periods(run_days: Array[int]) -> void:
	var selected_keys: Dictionary[Globals.ScoreBoard, String] = {}
	for score_board in [Globals.ScoreBoard.Daily, Globals.ScoreBoard.Weekly]:
		var selected_period: BoardPeriod = _get_selected_period(score_board)
		if selected_period != null:
			selected_keys[score_board] = selected_period.key

	var today_day: int = LeaderboardManager.get_today_day()
	var this_monday: int = _week_monday(today_day)
	var day_periods: Array[BoardPeriod] = []
	var week_periods: Array[BoardPeriod] = []
	for run_day in run_days:
		if today_day - run_day < int(Configs.Leaderboard.daily_history_days):
			var day_period: BoardPeriod = BoardPeriod.new(DAY_PERIOD_KEY % run_day, _describe_day(today_day - run_day, run_day), _format_date(run_day))
			day_period.run_days.append(run_day)
			day_periods.append(day_period)

		var week_monday: int = _week_monday(run_day)
		var weeks_ago: int = floori(float(this_monday - week_monday) / DAYS_PER_WEEK)
		if weeks_ago >= int(Configs.Leaderboard.weekly_history_weeks):
			continue
		if week_periods.is_empty() or week_periods.back().key != WEEK_PERIOD_KEY % week_monday:
			var week_dates: String = Literals.WEEK_DATES_CAPTION % [_format_date(week_monday), _format_date(week_monday + DAYS_PER_WEEK - 1)]
			week_periods.append(BoardPeriod.new(WEEK_PERIOD_KEY % week_monday, _describe_week(weeks_ago), week_dates))
		week_periods.back().run_days.append(run_day)

	_board_periods[Globals.ScoreBoard.Daily] = day_periods
	_board_periods[Globals.ScoreBoard.Weekly] = week_periods
	for score_board in selected_keys:
		var kept_index: int = _board_periods[score_board].find_custom(func(board_period: BoardPeriod) -> bool: return board_period.key == selected_keys[score_board])
		_period_indexes[score_board] = maxi(kept_index, 0)

#returns the period the tab shows, or null while the tab has none
func _get_selected_period(score_board: Globals.ScoreBoard) -> BoardPeriod:
	var periods: Array = _board_periods.get(score_board, [])
	if periods.is_empty():
		return null
	return periods[clampi(_period_indexes[score_board], 0, periods.size() - 1)]

#returns the day caption: today, yesterday, or the weekday name
func _describe_day(day_offset: int, run_day: int) -> String:
	if day_offset == 0:
		return Literals.TODAY_DAY_CAPTION
	if day_offset == 1:
		return Literals.YESTERDAY_CAPTION
	return Literals.WEEKDAY_CAPTIONS[run_day - _week_monday(run_day)]

#returns the week caption: this week, last week, or just week
func _describe_week(weeks_ago: int) -> String:
	if weeks_ago == 0:
		return Literals.THIS_WEEK_CAPTION
	if weeks_ago == 1:
		return Literals.LAST_WEEK_CAPTION
	return Literals.OLDER_WEEK_CAPTION

#returns the Monday of the calendar week holding the day; 1970-01-01 was a Thursday
func _week_monday(run_day: int) -> int:
	return run_day - posmod(run_day + 3, DAYS_PER_WEEK)

#returns a day counted since 1970-01-01 as d.M.
func _format_date(run_day: int) -> String:
	var run_date: Dictionary = Time.get_date_dict_from_unix_time(run_day * LeaderboardManager.DAY_SECONDS)
	return "%d.%d." % [run_date.day, run_date.month]

#marks the chosen tab and shows its selected period
func _select_board(score_board: Globals.ScoreBoard) -> void:
	_selected_board = score_board
	#set without signals, which skips the button group, so every tab is set
	for board_option in _board_tabs:
		_board_tabs[board_option].set_pressed_no_signal(board_option == score_board)
	_show_selected_period()

#shows the stepper for the selected period and its rows, fetching what was not fetched before;
#a tab without periods shows why: loading, failed, offline, or no scores at all
func _show_selected_period() -> void:
	if not LeaderboardManager.is_enabled():
		_period_stepper.visible = false
		_show_board_status(Literals.BOARD_OFFLINE_MESSAGE)
		return

	var selected_period: BoardPeriod = _get_selected_period(_selected_board)
	_period_stepper.visible = selected_period != null
	if selected_period == null:
		_show_board_status(_run_days_status if not _run_days_status.is_empty() else Literals.EMPTY_BOARD_MESSAGE)
		return

	var periods: Array = _board_periods[_selected_board]
	var period_index: int = _period_indexes[_selected_board]
	_period_top_label.text = selected_period.top_caption
	_period_dates_label.text = selected_period.dates_caption
	var has_steps: bool = periods.size() > 1
	_older_button.visible = has_steps
	_newer_button.visible = has_steps
	_older_button.disabled = period_index >= periods.size() - 1
	_newer_button.disabled = period_index <= 0
	_older_button.modulate.a = DISABLED_ARROW_ALPHA if _older_button.disabled else 1.0
	_newer_button.modulate.a = DISABLED_ARROW_ALPHA if _newer_button.disabled else 1.0

	var period_key: String = selected_period.key
	var fetch_key: String = FETCH_KEY % [period_key, _fetch_generation]
	if not _period_entries.has(period_key):
		_show_board_status(Literals.BOARD_LOADING_MESSAGE)
		if not _fetching_entries.has(period_key):
			_fetching_entries[period_key] = true
			LeaderboardManager.fetch_rankings(fetch_key, selected_period.run_days)
		return

	var rank_entries: Array = _period_entries[period_key]
	if not _has_own_entry(rank_entries) and not _period_standings.has(period_key):
		_show_board_status(Literals.BOARD_LOADING_MESSAGE)
		if not _fetching_standings.has(period_key):
			_fetching_standings[period_key] = true
			LeaderboardManager.fetch_player_standing(fetch_key, _rank_count_caps[_selected_board], selected_period.run_days)
		return

	_populate_leaderboard(rank_entries, _period_standings.get(period_key, {}))

#true when the player is among the best entries; otherwise the own standing below them is fetched
func _has_own_entry(rank_entries: Array) -> bool:
	var player_id: String = LeaderboardManager.get_player_id()
	return rank_entries.any(func(rank_entry: Dictionary) -> bool: return rank_entry.player_id == player_id)

#empties the rows and the rank chips and shows the status in place of the list
func _show_board_status(status_text: String) -> void:
	_clear_rows()
	_list_layout.visible = false
	_rank_chip.visible = false
	_no_result_chip.visible = false
	_board_status_label.text = status_text

#removes every row at once, so the new rows lay out alone
func _clear_rows() -> void:
	_own_row = null
	for row_list: VBoxContainer in [_podium_rows, _rest_rows]:
		for score_row in row_list.get_children():
			row_list.remove_child(score_row)
			score_row.queue_free()

#rebuilds the podium and the scrolling rows, the player's own row below them when lower,
#marks the player's rank on the chip and centers the list on the player's row
func _populate_leaderboard(rank_entries: Array, own_standing: Dictionary) -> void:
	if rank_entries.is_empty():
		_show_board_status(Literals.EMPTY_BOARD_MESSAGE)
		return

	_clear_rows()
	_board_status_label.text = ""
	_list_layout.visible = true

	var player_id: String = LeaderboardManager.get_player_id()
	var own_rank: int = 0
	for entry_index in rank_entries.size():
		var rank_entry: Dictionary = rank_entries[entry_index]
		var is_own_standing: bool = rank_entry.player_id == player_id
		var is_podium: bool = entry_index < PODIUM_SIZE
		var score_row: ScoreRow = (PODIUM_ROW_SCENE if is_podium else RANK_ROW_SCENE).instantiate() as ScoreRow
		(_podium_rows if is_podium else _rest_rows).add_child(score_row)
		score_row.setup(entry_index + 1, rank_entry.username, rank_entry.score, is_own_standing)
		if is_own_standing:
			own_rank = entry_index + 1
			_own_row = score_row

	#below the best scores the rank counts the players above, shown as "> count" once the tab's cap stopped the count
	var is_below_top: bool = own_rank == 0 and not own_standing.is_empty()
	var below_top_caption: String = ""
	if is_below_top:
		var rank_caption: String = Literals.BOARD_BELOW_TOP_CAPTION if own_standing.is_rank_capped else Literals.BOARD_RANK_CAPTION
		below_top_caption = rank_caption % own_standing.rank
		_rest_rows.add_child(_create_gap_label())
		_own_row = RANK_ROW_SCENE.instantiate() as ScoreRow
		_rest_rows.add_child(_own_row)
		_own_row.setup(0, own_standing.username, own_standing.score, true, below_top_caption)

	_rank_chip.visible = own_rank > 0 or is_below_top
	_no_result_chip.visible = not _rank_chip.visible
	_chip_rank_label.text = below_top_caption if is_below_top else Literals.BOARD_RANK_CAPTION % own_rank
	_paint_rank_chip(own_rank)
	_no_result_label.text = Literals.BOARD_NO_RESULT_CAPTIONS[_selected_board]

	#the rows lay out during this frame, so the list scrolls on the next one
	if not get_tree().process_frame.is_connected(_center_own_row_at_once):
		get_tree().process_frame.connect(_center_own_row_at_once, CONNECT_ONE_SHOT)

#colors the rank chip gold, silver or bronze for a podium rank, purple for any lower one
func _paint_rank_chip(own_rank: int) -> void:
	var is_podium_rank: bool = own_rank >= 1 and own_rank <= podium_chip_styles.size()
	_rank_chip.add_theme_stylebox_override("panel", podium_chip_styles[own_rank - 1] if is_podium_rank else _own_chip_style)
	_chip_rank_label.add_theme_color_override("font_color", podium_chip_text_color if is_podium_rank else _own_chip_text_color)

#builds the row standing between the best scores and the player's lower own row
func _create_gap_label() -> Label:
	var gap_label: Label = Label.new()
	gap_label.text = Literals.BOARD_GAP_CAPTION
	gap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gap_label.add_theme_font_override("font", gap_font)
	gap_label.add_theme_font_size_override("font_size", GAP_FONT_SIZE)
	gap_label.add_theme_color_override("font_color", GAP_FONT_COLOR)
	return gap_label

#shows in red above the back button for a moment that a resent run score did not go out
func _show_submit_note(note_text: String) -> void:
	_submit_note_label.text = note_text
	_submit_note_label.add_theme_color_override("font_color", NOTE_ERROR_COLOR)
	_submit_note_label.visible = true
	if _note_tween != null:
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_interval(SUBMIT_NOTE_DURATION)
	_note_tween.tween_callback(_submit_note_label.hide)

#shows a yellow message over the bottom of the board for SNACKBAR_DURATION, fading in and out
func _show_snackbar(message_text: String) -> void:
	_snackbar_label.text = message_text
	_snackbar.modulate.a = 0.0
	_snackbar.visible = true
	if _snackbar_tween != null:
		_snackbar_tween.kill()
	_snackbar_tween = create_tween()
	_snackbar_tween.tween_property(_snackbar, "modulate:a", 1.0, SNACKBAR_FADE_DURATION)
	_snackbar_tween.tween_interval(SNACKBAR_DURATION - SNACKBAR_FADE_DURATION * 2.0)
	_snackbar_tween.tween_property(_snackbar, "modulate:a", 0.0, SNACKBAR_FADE_DURATION)
	_snackbar_tween.tween_callback(_snackbar.hide)

#scrolls the list so the player's row sits in its middle; the top when the player is on the podium or not listed
func _center_own_row(is_animated: bool) -> void:
	var scroll_target: float = 0.0
	if _own_row != null and _own_row.get_parent() == _rest_rows:
		var row_center: float = _own_row.global_position.y - _rest_margin.global_position.y + _own_row.size.y / 2.0
		scroll_target = row_center - _rest_scroll.size.y / 2.0
	scroll_target = clampf(scroll_target, 0.0, maxf(_rest_margin.size.y - _rest_scroll.size.y, 0.0))

	if _scroll_tween != null:
		_scroll_tween.kill()
	if not is_animated:
		_rest_scroll.scroll_vertical = roundi(scroll_target)
		return
	_scroll_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(_rest_scroll, "scroll_vertical", roundi(scroll_target), CENTER_SCROLL_DURATION)

#signal SceneTree.process_frame => once the new rows are laid out, the list jumps to the player's row
func _center_own_row_at_once() -> void:
	_center_own_row(false)

#signal Signals.run_days_fetched => builds the day and week periods, or shows that the leaderboard did not load;
#an answer from before the entries went stale is dropped
func _on_run_days_fetched(fetch_key: String, fetch_succeeded: bool, run_days: Array[int]) -> void:
	if fetch_key != FETCH_KEY % [RUN_DAYS_FETCH_KEY, _fetch_generation]:
		return
	if not fetch_succeeded:
		_run_days_status = Literals.BOARD_FAILED_MESSAGE
		if _selected_board != Globals.ScoreBoard.Total:
			_show_selected_period()
		return

	_run_days_status = ""
	_build_periods(run_days)
	_show_selected_period()

#signal Signals.ranks_fetched => keeps the period's best entries and shows the period if it is still selected
func _on_ranks_fetched(fetch_key: String, fetch_succeeded: bool, rank_entries: Array[Dictionary]) -> void:
	_on_period_fetched(fetch_key, fetch_succeeded, rank_entries, _period_entries, _fetching_entries)

#signal Signals.player_standing_fetched => keeps the player's standing in the period and shows the period if it is still selected
func _on_player_standing_fetched(fetch_key: String, fetch_succeeded: bool, own_standing: Dictionary) -> void:
	_on_period_fetched(fetch_key, fetch_succeeded, own_standing, _period_standings, _fetching_standings)

#keeps a fetched answer by period key and shows the period if it is still selected;
#a failed fetch is forgotten, so selecting the period again tries again; an answer from before the entries went stale is dropped
func _on_period_fetched(fetch_key: String, fetch_succeeded: bool, fetched_value: Variant, fetched_values: Dictionary, fetching_keys: Dictionary) -> void:
	var period_key: String = fetch_key.get_slice("#", 0)
	if fetch_key != FETCH_KEY % [period_key, _fetch_generation]:
		return
	fetching_keys.erase(period_key)
	if fetch_succeeded:
		fetched_values[period_key] = fetched_value

	var selected_period: BoardPeriod = _get_selected_period(_selected_board)
	if selected_period == null or selected_period.key != period_key:
		return
	if fetch_succeeded:
		_show_selected_period()
	else:
		_show_board_status(Literals.BOARD_FAILED_MESSAGE)

#shows the learning run score and drops it, as learning runs never reach the leaderboard
func _show_learning_points() -> void:
	_show_snackbar(Literals.LEARNING_SCORE_MESSAGE % DialogScoreCalculator.format_points(_run_points))
	LeaderboardManager.clear_stored_points()
	_run_points = LeaderboardManager.NO_RUN_POINTS_PENDING

#signal Signals.score_submitted => a waiting run score sent from here; once stored, the boards are fetched anew to hold it,
#also when a higher all-time score was kept, since today's board may still have taken the run; a failed send or a kept higher score is noted
func _on_score_submitted(submit_result: Globals.ScoreSubmit) -> void:
	if not _is_submitting:
		return
	_is_submitting = false
	var formatted_points: String = DialogScoreCalculator.format_points(_run_points)
	if submit_result == Globals.ScoreSubmit.Failed:
		_show_submit_note(Literals.FAILED_MESSAGE % formatted_points)
		return

	LeaderboardManager.clear_stored_points()
	if submit_result == Globals.ScoreSubmit.Accepted:
		SoundManager.play_stinger(Globals.Sound.Points)
	else:
		_show_snackbar(Literals.SCORE_HIGHER_MESSAGE % formatted_points)
	_fetch_generation += 1
	_period_entries.clear()
	_period_standings.clear()
	_fetching_entries.clear()
	_fetching_standings.clear()
	LeaderboardManager.fetch_run_days(FETCH_KEY % [RUN_DAYS_FETCH_KEY, _fetch_generation])

#signal Button.pressed => a tap on a tab selects it
func _on_board_tab_pressed(score_board: Globals.ScoreBoard) -> void:
	if score_board == _selected_board:
		return
	SoundManager.play_stinger(Globals.Sound.MenuSelect)
	_select_board(score_board)

#signal Button.pressed => an arrow steps to the next period; 1 towards older periods, -1 towards the latest
func _on_period_arrow_pressed(period_step: int) -> void:
	var periods: Array = _board_periods.get(_selected_board, [])
	var period_index: int = clampi(_period_indexes[_selected_board] + period_step, 0, maxi(periods.size() - 1, 0))
	if period_index == _period_indexes[_selected_board]:
		return
	SoundManager.play_stinger(Globals.Sound.MenuSelect)
	_period_indexes[_selected_board] = period_index
	_show_selected_period()

#signal Control.gui_input => a tap on the rank chip glides the list to the player's row;
#touch only, since a mouse click also arrives as an emulated touch
func _on_rank_chip_input(input_event: InputEvent) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		_center_own_row(true)

#signal Button.pressed => opens the rewards screen
func _on_rewards_pressed() -> void:
	SoundManager.play_stinger(Globals.Sound.MenuSelect)
	_rewards_screen.visible = true

#signal Button.pressed => returns to the start screen
func _on_back_pressed() -> void:
	GameManager.switch_screen(GameManager.GameScreen.START)
