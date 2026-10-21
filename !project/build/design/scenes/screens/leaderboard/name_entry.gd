##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : Name step after a run: shows the run score, claims the leaderboard username, submits the score, then opens the leaderboard
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name NameEntryScreen
extends Control

#px kept between the name field and the top of the virtual keyboard
const KEYBOARD_MARGIN: float = 24.0
#how quickly the panel follows the virtual keyboard, as the share of the remaining distance covered per s
const LIFT_SPEED: float = 12.0
#share of the browser window below the visual viewport, which is what the virtual keyboard covers on web
const WEB_KEYBOARD_SHARE_JS: String = "(function(){var v=window.visualViewport;if(!v||!window.innerHeight)return 0;return Math.max(0,1-(v.height+v.offsetTop)/window.innerHeight);})()"

#private vars
var _run_points: int = LeaderboardManager.NO_RUN_POINTS_PENDING
#true from a valid DALJE until the claim or the submit answers; repeated taps are ignored meanwhile
var _is_sending: bool = false
#true once the name or the score could not be sent, so the next DALJE goes on to the leaderboard with the score still waiting
var _has_failed: bool = false

#onready vars
@onready var _panel: PanelContainer = %Panel
@onready var _score_plaque: PanelContainer = %ScorePlaque
@onready var _caption_label: Label = %CaptionLabel
@onready var _points_label: Label = %PointsLabel
@onready var _title_label: Label = %TitleLabel
@onready var _username_field: LineEdit = %UsernameField
@onready var _hint_label: Label = %HintLabel
@onready var _counter_label: Label = %CounterLabel
@onready var _error_label: Label = %ErrorLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _continue_content: HBoxContainer = %ContinueContent
@onready var _continue_label: Label = %ContinueLabel
@onready var _spinner: PixelSpinner = %Spinner

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_caption_label.text = Literals.USERNAME_POINTS_CAPTION
	_title_label.text = Literals.USERNAME_TITLE
	_hint_label.text = Literals.USERNAME_HINT
	_continue_label.text = Literals.USERNAME_CONTINUE
	_username_field.max_length = Configs.Leaderboard.username_length
	_username_field.text = LeaderboardManager.get_username()
	_username_field.caret_column = _username_field.text.length()
	_update_counter()
	_clear_error()

	_username_field.text_changed.connect(_on_username_changed)
	_username_field.text_submitted.connect(_on_username_submitted)
	_continue_button.pressed.connect(_confirm_username)

	Signals.user_saved.connect(_on_user_saved)
	Signals.user_refused.connect(_on_user_refused)
	Signals.score_submitted.connect(_on_score_submitted)

	_run_points = LeaderboardManager.get_run_points()
	_score_plaque.visible = _run_points != LeaderboardManager.NO_RUN_POINTS_PENDING
	_points_label.text = ScoreRow.group_score_digits(_run_points)
	#a returning player only confirms the saved name, so the keyboard opens only for a missing one
	if not LeaderboardManager.is_valid_username(_username_field.text):
		_username_field.grab_focus.call_deferred()
	#only a virtual keyboard can cover the name field
	set_process(DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD))

#keeps the panel centered, lifted while the virtual keyboard would cover the name field
func _process(delta: float) -> void:
	var target_y: float = (size.y - _panel.size.y) / 2.0
	var keyboard_top: float = _get_keyboard_top()
	if keyboard_top < INF:
		var field_bottom_in_panel: float = _username_field.get_global_rect().end.y - _panel.global_position.y
		target_y = minf(target_y, keyboard_top - KEYBOARD_MARGIN - field_bottom_in_panel)
	_panel.position.y = lerpf(_panel.position.y, target_y, minf(1.0, LIFT_SPEED * delta))

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#claims the typed username, or submits right away when it is the saved one; shows why a username is not valid;
#after a failed claim or submit it goes on to the leaderboard instead
func _confirm_username() -> void:
	if _is_sending:
		return
	if _has_failed:
		GameManager.go_to_leaderboard()
		return

	var typed_username: String = _username_field.text.strip_edges()
	_username_field.release_focus()
	if not LeaderboardManager.is_valid_username(typed_username):
		_show_error(_describe_refused_username(typed_username))
		return

	_clear_error()
	_set_sending(true)
	if typed_username == LeaderboardManager.get_username():
		_submit_points()
		return
	LeaderboardManager.claim_username(typed_username)

#explains why LeaderboardManager found the username not valid; the checks below mirror its is_valid_username rules
func _describe_refused_username(typed_username: String) -> String:
	if typed_username.is_empty():
		return Literals.USERNAME_EMPTY_MESSAGE
	if typed_username.length() > Configs.Leaderboard.username_length:
		return Literals.USERNAME_TOO_LONG_MESSAGE % Configs.Leaderboard.username_length
	return Literals.USERNAME_INVALID_CHARACTER_MESSAGE

#sends the run score under the saved username; without a run score waiting the leaderboard opens right away
func _submit_points() -> void:
	if _run_points == LeaderboardManager.NO_RUN_POINTS_PENDING:
		GameManager.go_to_leaderboard()
		return
	LeaderboardManager.submit_score(_run_points)

#shows the typed length against the allowed one
func _update_counter() -> void:
	_counter_label.text = Literals.USERNAME_COUNTER_CAPTION % [_username_field.text.length(), Configs.Leaderboard.username_length]

#while a claim or a submit is out DALJE spins instead of showing its label, and repeated taps are ignored
func _set_sending(is_sending: bool) -> void:
	_is_sending = is_sending
	_continue_content.visible = not is_sending
	_spinner.visible = is_sending

#shows an error line below the name
func _show_error(error_text: String) -> void:
	_error_label.text = error_text
	_error_label.visible = true

func _clear_error() -> void:
	_error_label.text = ""
	_error_label.visible = false

#the top of the virtual keyboard in this screen's coordinates, INF while it is closed
func _get_keyboard_top() -> float:
	var keyboard_height: float = _get_keyboard_height()
	if keyboard_height < 1.0:
		return INF
	var window_keyboard_top: Vector2 = Vector2(0.0, DisplayServer.window_get_size().y - keyboard_height)
	var canvas_keyboard_top: Vector2 = get_viewport().get_final_transform().affine_inverse() * window_keyboard_top
	return canvas_keyboard_top.y - global_position.y

#window px the virtual keyboard covers, 0 while it is closed; browsers report no keyboard height,
#only the visual viewport shrinking above it
func _get_keyboard_height() -> float:
	if not OS.has_feature("web"):
		return DisplayServer.virtual_keyboard_get_height()
	var covered_share: Variant = JavaScriptBridge.eval(WEB_KEYBOARD_SHARE_JS)
	if typeof(covered_share) != TYPE_FLOAT and typeof(covered_share) != TYPE_INT:
		return 0.0
	return float(covered_share) * DisplayServer.window_get_size().y

#signal Signals.user_saved => the claimed name is the player's, so the run score goes out under it
func _on_user_saved(saved_username: String) -> void:
	if not _is_sending:
		return
	_username_field.text = saved_username
	_submit_points()

#signal Signals.user_refused => shows that the name is taken or could not be saved; after a taken name DALJE tries again,
#after a failed save it goes on to the leaderboard
func _on_user_refused(refuse_reason: Globals.NameRefuse) -> void:
	if not _is_sending:
		return
	_set_sending(false)
	if refuse_reason == Globals.NameRefuse.Taken:
		_show_error(Literals.USERNAME_TAKEN_MESSAGE)
		return
	_has_failed = true
	_show_error(Literals.USERNAME_NOT_SAVED_MESSAGE)

#signal Signals.score_submitted => a stored score opens the leaderboard, which also says when a higher one was already stored;
#a failed submit keeps the score waiting and the next DALJE goes on to the leaderboard, which resends it
#on a later visit while the player has a saved name, until the next run replaces it
func _on_score_submitted(submit_result: Globals.ScoreSubmit) -> void:
	if not _is_sending:
		return
	match submit_result:
		Globals.ScoreSubmit.Accepted:
			LeaderboardManager.clear_stored_points()
			SoundManager.play_stinger(Globals.Sound.Points)
			GameManager.go_to_leaderboard()
		Globals.ScoreSubmit.Stored:
			LeaderboardManager.clear_stored_points()
			LeaderboardManager.set_declined_points(_run_points)
			GameManager.go_to_leaderboard()
		Globals.ScoreSubmit.Failed:
			_set_sending(false)
			_has_failed = true
			_show_error(Literals.FAILED_MESSAGE % DialogScoreCalculator.format_points(_run_points))

#signal LineEdit.text_changed => updates the counter and clears the previous error; a changed name is tried again on DALJE
func _on_username_changed(_changed_text: String) -> void:
	_update_counter()
	if not _is_sending:
		_has_failed = false
		_clear_error()

#signal LineEdit.text_submitted => the keyboard enter/done key confirms the username
func _on_username_submitted(_submitted_text: String) -> void:
	_confirm_username()
