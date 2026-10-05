##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Leaderboard screen; lists the best scores with the player's row highlighted,
#                  submits the finished run score under the stored username, or prompts
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name LeaderboardScreen
extends Control

const ROW_FONT_SIZE: int = 52
const ROW_RANK_WIDTH: float = 110.0
const ROW_SCORE_WIDTH: float = 220.0
const ROW_INNER_MARGIN: float = 16.0
const PLAYER_HIGHLIGHT: Color = Color(0.08235294, 0.078431375, 0.09803922, 0.18)

#private vars
var _run_points: int = LeaderboardManager.NO_RUN_POINTS_PENDING
var _is_submitting: bool = false
var _is_score_settled: bool = false
var _top_entries: Array[Dictionary] = []
var _is_board_loaded: bool = false
var _is_fetching: bool = false
var _is_refetch_pending: bool = false

#onready vars
@onready var _submit_status_label: RichTextLabel = $SubmitStatusLabel
@onready var _username_form: UsernameForm = $UsernameForm
@onready var _score_rows: VBoxContainer = $Board/BoardMargin/ScoreScroll/ScoreRows
@onready var _board_status_label: RichTextLabel = $Board/BoardStatusLabel
@onready var _back_button: Control = $BackButton

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
	_run_points = LeaderboardManager.get_run_points()
	if not LeaderboardManager.is_enabled():
		_board_status_label.text = Literals.BOARD_OFFLINE_MESSAGE
		return

	Signals.ranks_fetched.connect(_on_top_scores_received)
	Signals.user_saved.connect(_on_user_saved)
	_top_scores_refresh()
	if _run_points == LeaderboardManager.NO_RUN_POINTS_PENDING:
		return

	Signals.score_submitted.connect(_on_score_submitted)

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

#asks for the best scores and shows the loading state until they arrive;
#while a fetch is on its way one more is queued, so an older answer never replaces a newer board
func _top_scores_refresh() -> void:
	if _is_fetching:
		_is_refetch_pending = true
		return
	_is_fetching = true
	if not _is_board_loaded:
		_board_status_label.text = Literals.BOARD_LOADING_MESSAGE
	LeaderboardManager.fetch_rankings()

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

#signal Signals.ranks_fetched => shows the best scores, or why there are none
func _on_top_scores_received(fetch_succeeded: bool, top_entries: Array[Dictionary]) -> void:
	_is_fetching = false
	if fetch_succeeded:
		_is_board_loaded = true
		_top_entries = top_entries
		_populate_leaderboard()
	elif not _is_board_loaded:
		_board_status_label.text = Literals.BOARD_FAILED_MESSAGE
	if _is_refetch_pending:
		_is_refetch_pending = false
		_top_scores_refresh()

#signal Signals.user_saved => refreshes the board for the new name and submits a score still waiting for a name or a retry
func _on_user_saved(_saved_username: String) -> void:
	if _run_points == LeaderboardManager.NO_RUN_POINTS_PENDING or _is_submitting or _is_score_settled:
		_top_scores_refresh()
		return
	_submit_points()

#signal Control.gui_input => a tap on the back button returns to the start screen;
#touch only, since a mouse click also arrives as an emulated touch
func _on_back_button(input_event: InputEvent) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		GameManager.switch_screen(GameManager.GameScreen.START)
