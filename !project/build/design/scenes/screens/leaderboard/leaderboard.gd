##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Shows the scores by tab and day, submitting the finished runs
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
class_name LeaderboardScreen
extends Control

const ROW_FONT_SIZE: int = 52
const ROW_RANK_WIDTH: float = 110.0
const ROW_SCORE_WIDTH: float = 220.0
const ROW_INNER_MARGIN: float = 16.0
const PLAYER_HIGHLIGHT: Color = Color(0.08235294, 0.078431375, 0.09803922, 0.18)

const UNSELECTED_TAB_ALPHA: float = 0.45
const DAY_TAB_WIDTH: float = 200.0
const WEEK_TAB_WIDTH: float = 250.0

#private vars
var _run_points: int = LeaderboardManager.NO_RUN_POINTS_PENDING
var _is_submitting: bool = false
var _is_score_settled: bool = false
var _top_entries: Array[Dictionary] = []
var _is_board_loaded: bool = false
var _is_fetching: bool = false
var _is_refetch_pending: bool = false
var _selected_board: Globals.ScoreBoard = Globals.ScoreBoard.Daily
var _selected_period_offset: int = 0

#onready vars
@onready var _submit_status_label: RichTextLabel = $SubmitStatusLabel
@onready var _username_form: UsernameForm = $UsernameForm
@onready var _score_rows: VBoxContainer = $Board/BoardMargin/ScoreScroll/ScoreRows
@onready var _board_status_label: RichTextLabel = $Board/BoardStatusLabel
@onready var _back_button: Control = $BackButton
@onready var _board_tabs: Dictionary[Globals.ScoreBoard, Control] = {
	Globals.ScoreBoard.Daily: $Board/ScoreTabs/DailyTab,
	Globals.ScoreBoard.Weekly: $Board/ScoreTabs/WeeklyTab,
	Globals.ScoreBoard.Total: $Board/ScoreTabs/TotalTab,
	Globals.ScoreBoard.Rewards: $Board/ScoreTabs/RewardsTab,
}
@onready var _period_strip: HBoxContainer = $Board/PeriodStrip
@onready var _period_scroll: ScrollContainer = $Board/PeriodStrip/PeriodScroll
@onready var _period_tabs: HBoxContainer = $Board/PeriodStrip/PeriodScroll/PeriodTabs
@onready var _period_tab_template: Control = $Board/PeriodStrip/PeriodScroll/PeriodTabs/PeriodTab
@onready var _left_arrow: Control = $Board/PeriodStrip/LeftArrow
@onready var _right_arrow: Control = $Board/PeriodStrip/RightArrow

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_submit_status_label.text = ""
	_back_button.gui_input.connect(_on_back_button)
	for score_board in _board_tabs:
		_board_tabs[score_board].gui_input.connect(_on_board_tab.bind(score_board))
	_period_tab_template.gui_input.connect(_on_period_tab.bind(0))
	_left_arrow.gui_input.connect(_on_period_arrow.bind(-1))
	_right_arrow.gui_input.connect(_on_period_arrow.bind(1))
	_period_strip.resized.connect(_update_period_arrows)
	_period_tabs.resized.connect(_update_period_arrows)

	Signals.ranks_fetched.connect(_on_top_scores_received)
	Signals.user_saved.connect(_on_user_saved)
	Signals.score_submitted.connect(_on_score_submitted)

	_select_board(Globals.ScoreBoard.Daily)

	_run_points = LeaderboardManager.get_run_points()
	if not LeaderboardManager.is_enabled():
		_board_status_label.text = Literals.BOARD_OFFLINE_MESSAGE
		return
	if _run_points == LeaderboardManager.NO_RUN_POINTS_PENDING:
		return

	if LeaderboardManager.is_valid_username(LeaderboardManager.get_username()):
		_submit_points()
	else:
		_submit_status_label.text = Literals.MISSING_USERNAME_MESSAGE % _run_points
		_username_form.prompt_username()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#refills the strip with one tab per day or per calendar week, the latest first and older ones to the right
func _build_period_tabs(score_board: Globals.ScoreBoard) -> void:
	for period_tab in _period_tabs.get_children():
		if period_tab != _period_tab_template:
			_period_tabs.remove_child(period_tab)
			period_tab.queue_free()

	var is_daily: bool = score_board == Globals.ScoreBoard.Daily
	var period_count: int = int(Configs.Leaderboard.daily_history_days if is_daily else Configs.Leaderboard.weekly_history_weeks)
	_period_tab_template.custom_minimum_size.x = DAY_TAB_WIDTH if is_daily else WEEK_TAB_WIDTH
	for period_offset in range(1, period_count):
		var period_tab: Control = _period_tab_template.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_USE_INSTANTIATION)
		period_tab.gui_input.connect(_on_period_tab.bind(period_offset))
		_period_tabs.add_child(period_tab)

	var today_day: int = _today_day()
	for period_offset in period_count:
		var period_caption: String = _describe_day(period_offset, today_day - period_offset) if is_daily else _describe_week(today_day - period_offset * 7)
		_period_tabs.get_child(period_offset).get_node("PeriodLabel").text = period_caption

	_select_period(0)

#returns today in whole days since 1970-01-01 shifted by Configs.Leaderboard.day_utc_offset, from the device clock
func _today_day() -> int:
	var shifted_seconds: int = int(Time.get_unix_time_from_system()) + int(Configs.Leaderboard.day_utc_offset) * LeaderboardManager.HOUR_SECONDS
	return floori(float(shifted_seconds) / LeaderboardManager.DAY_SECONDS)

#returns the day tab caption: today, yesterday, or the date as dd.MM.
func _describe_day(day_offset: int, run_day: int) -> String:
	if day_offset == 0:
		return Literals.TODAY_DAY_CAPTION
	if day_offset == 1:
		return Literals.YESTERDAY_CAPTION
	return _format_date(run_day)

#returns the week tab caption: its Monday and Sunday dates
func _describe_week(run_day: int) -> String:
	var week_monday: int = _week_monday(run_day)
	return Literals.WEEK_CAPTION % [_format_date(week_monday), _format_date(week_monday + 6)]

#returns the Monday of the calendar week holding the day; 1970-01-01 was a Thursday
func _week_monday(run_day: int) -> int:
	return run_day - posmod(run_day + 3, 7)

#returns the run days the selected tab covers: the chosen day, the chosen week up to today, or none for the all-time board
func _selected_run_days() -> Array[int]:
	var today_day: int = _today_day()
	var run_days: Array[int] = []
	match _selected_board:
		Globals.ScoreBoard.Daily:
			run_days.append(today_day - _selected_period_offset)
		Globals.ScoreBoard.Weekly:
			var week_monday: int = _week_monday(today_day - _selected_period_offset * 7)
			run_days.assign(range(week_monday, mini(week_monday + 7, today_day + 1)))
	return run_days

#returns a day counted since 1970-01-01 as dd.MM.
func _format_date(run_day: int) -> String:
	var run_date: Dictionary = Time.get_date_dict_from_unix_time(run_day * LeaderboardManager.DAY_SECONDS)
	return "%02d.%02d." % [run_date.day, run_date.month]

#marks the chosen tab; the strip shows days on the daily tab, weeks on the weekly tab, and hides on the total and rewards tabs
func _select_board(score_board: Globals.ScoreBoard) -> void:
	_selected_board = score_board
	for board_option in _board_tabs:
		_board_tabs[board_option].modulate.a = 1.0 if board_option == score_board else UNSELECTED_TAB_ALPHA

	_period_strip.visible = score_board in [Globals.ScoreBoard.Daily, Globals.ScoreBoard.Weekly]
	if _period_strip.visible:
		_build_period_tabs(score_board)
	else:
		_show_selected_board()

#marks the chosen day or week tab and scrolls it into view once the strip is laid out
func _select_period(period_offset: int) -> void:
	_selected_period_offset = period_offset
	for period_tab in _period_tabs.get_children():
		period_tab.modulate.a = 1.0 if period_tab.get_index() == period_offset else UNSELECTED_TAB_ALPHA

	_period_scroll.ensure_control_visible.call_deferred(_period_tabs.get_child(period_offset))
	_show_selected_board()

#empties the board and fetches the selected tab and period; the rewards tab stays blank for now
func _show_selected_board() -> void:
	if not LeaderboardManager.is_enabled():
		return

	_top_entries = []
	_populate_leaderboard()
	if _selected_board == Globals.ScoreBoard.Rewards:
		_board_status_label.text = ""
		return

	_is_board_loaded = false
	_top_scores_refresh()

#shows the arrows only when the period tabs are wider than the strip
func _update_period_arrows() -> void:
	var is_overflowing: bool = _period_tabs.size.x > _period_strip.size.x
	_left_arrow.visible = is_overflowing
	_right_arrow.visible = is_overflowing

#asks for the best scores of the selected tab and period and shows the loading state until they arrive;
#while a fetch is on its way one more is queued, so an older answer never replaces a newer board;
#the rewards tab has no scores to fetch
func _top_scores_refresh() -> void:
	if _selected_board == Globals.ScoreBoard.Rewards:
		return
	if _is_fetching:
		_is_refetch_pending = true
		return
	_is_fetching = true
	if not _is_board_loaded:
		_board_status_label.text = Literals.BOARD_LOADING_MESSAGE
	LeaderboardManager.fetch_rankings(_selected_run_days())

#rebuilds the score rows, highlighting the row stored under this install's player id
func _populate_leaderboard() -> void:
	for score_row in _score_rows.get_children():
		score_row.queue_free()
	var player_id: String = LeaderboardManager.get_player_id()
	for entry_index in _top_entries.size():
		var top_entry: Dictionary = _top_entries[entry_index]
		_score_rows.add_child(_create_player_standing(entry_index + 1, top_entry.username, top_entry.score, top_entry.player_id == player_id))
	_board_status_label.text = Literals.EMPTY_BOARD_MESSAGE if _top_entries.is_empty() else ""

#builds one rank / username / score row; the player's row gets a tinted background
func _create_player_standing(entry_rank: int, entry_username: String, entry_score: int, is_own_standing: bool) -> PanelContainer:
	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	row_style.bg_color = PLAYER_HIGHLIGHT if is_own_standing else Color.TRANSPARENT
	row_style.content_margin_left = ROW_INNER_MARGIN
	row_style.content_margin_right = ROW_INNER_MARGIN
	var score_row: PanelContainer = PanelContainer.new()
	score_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_row.add_theme_stylebox_override("panel", row_style)

	var row_columns: HBoxContainer = HBoxContainer.new()
	row_columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_row.add_child(row_columns)
	row_columns.add_child(_create_column_content("%d." % entry_rank, HORIZONTAL_ALIGNMENT_LEFT, ROW_RANK_WIDTH))
	var username_label: RichTextLabel = _create_column_content(entry_username, HORIZONTAL_ALIGNMENT_LEFT, 0.0)
	username_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	username_label.clip_contents = true
	row_columns.add_child(username_label)
	row_columns.add_child(_create_column_content(str(entry_score), HORIZONTAL_ALIGNMENT_RIGHT, ROW_SCORE_WIDTH))
	return score_row

#builds one single-line row cell styled by the board theme
func _create_column_content(cell_text: String, cell_alignment: HorizontalAlignment, cell_width: float) -> RichTextLabel:
	var row_label: RichTextLabel = RichTextLabel.new()
	row_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_label.fit_content = true
	row_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row_label.scroll_active = false
	row_label.horizontal_alignment = cell_alignment
	row_label.custom_minimum_size.x = cell_width
	row_label.add_theme_font_size_override("normal_font_size", ROW_FONT_SIZE)
	row_label.text = cell_text
	return row_label

#sends the run score under this player's id and shows that it is on its way
func _submit_points() -> void:
	_is_submitting = true
	_submit_status_label.text = Literals.SUBMIT_MESSAGE % _run_points
	LeaderboardManager.submit_score(_run_points)

#signal Signals.score_submitted => shows the outcome; a higher stored score is not an error
func _on_score_submitted(submit_result: Globals.ScoreSubmit) -> void:
	if not _is_submitting:
		return
	_is_submitting = false
	match submit_result:
		Globals.ScoreSubmit.Accepted:
			_is_score_settled = true
			LeaderboardManager.clear_stored_points()
			_submit_status_label.text = Literals.SCORE_SAVED_MESSAGE % _run_points
			_top_scores_refresh()
		Globals.ScoreSubmit.Stored:
			_is_score_settled = true
			LeaderboardManager.clear_stored_points()
			_submit_status_label.text = Literals.SCORE_HIGHER_MESSAGE % _run_points
		Globals.ScoreSubmit.Failed:
			_submit_status_label.text = Literals.FAILED_MESSAGE % _run_points

#signal Signals.ranks_fetched => shows the best scores, or why there are none;
#an answer outdated by a queued fetch, e.g. for a tab selected meanwhile, is dropped, as is any answer on the rewards tab
func _on_top_scores_received(fetch_succeeded: bool, top_entries: Array[Dictionary]) -> void:
	_is_fetching = false
	if _is_refetch_pending:
		_is_refetch_pending = false
		_top_scores_refresh()
		return
	if _selected_board == Globals.ScoreBoard.Rewards:
		return

	if fetch_succeeded:
		_is_board_loaded = true
		_top_entries = top_entries
		_populate_leaderboard()
	elif not _is_board_loaded:
		_board_status_label.text = Literals.BOARD_FAILED_MESSAGE

#signal Signals.user_saved => refreshes the board for the new name and submits a score still waiting for a name or a retry
func _on_user_saved(_saved_username: String) -> void:
	if _run_points == LeaderboardManager.NO_RUN_POINTS_PENDING or _is_submitting or _is_score_settled:
		_top_scores_refresh()
		return
	_submit_points()

#signal Control.gui_input => a tap on a score tab selects it
func _on_board_tab(input_event: InputEvent, score_board: Globals.ScoreBoard) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		_select_board(score_board)

#signal Control.gui_input => a tap on a day or week tab selects it
func _on_period_tab(input_event: InputEvent, period_offset: int) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		_select_period(period_offset)

#signal Control.gui_input => a tap on an arrow scrolls the period strip by one tab; -1 towards the latest, 1 towards older periods
func _on_period_arrow(input_event: InputEvent, scroll_direction: int) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		var day_tab_step: float = _period_tab_template.size.x + _period_tabs.get_theme_constant("separation")
		_period_scroll.scroll_horizontal += roundi(scroll_direction * day_tab_step)

#signal Control.gui_input => a tap on the back button returns to the start screen;
#touch only, since a mouse click also arrives as an emulated touch
func _on_back_button(input_event: InputEvent) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		GameManager.switch_screen(GameManager.GameScreen.START)
