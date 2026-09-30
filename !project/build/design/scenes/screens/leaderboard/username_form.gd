##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Leaderboard username field; claims the typed name through LeaderboardManager,
#                  which stores it once no other player has it, and explains why a name was refused
#author          : Zeljko Vulovic
#date            : 20260926
#version         : 1.0
#===============================================================================
class_name UsernameForm
extends Control

const SAVED_MESSAGE: String = "Name saved"
const CHECK_MESSAGE: String = "Checking name..."
const TAKEN_MESSAGE: String = "Name is taken"
const EMPTY_MESSAGE: String = "Name cannot be empty"
const TOO_LONG_MESSAGE: String = "Name can have at most %d characters"
const INVALID_CHARACTER_MESSAGE: String = "Name can use only letters A-Z, digits, space, _ and -"
const NOT_SAVED_MESSAGE: String = "Name could not be saved"

#private vars
var _is_claiming: bool = false

#onready vars
@onready var _username_field: LineEdit = $NameField/LineEdit
@onready var _confirm_button: Control = $ConfirmButton
@onready var _claim_feedback: RichTextLabel = $StatusLabel

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_username_field.max_length = Configs.Leaderboard.username_length
	_username_field.text = LeaderboardManager.get_username()
	_claim_feedback.text = ""
	_username_field.text_submitted.connect(_on_username_submitted)
	_username_field.text_changed.connect(_on_username_clear)
	_confirm_button.gui_input.connect(_on_confirm_button)
	Signals.user_saved.connect(_on_user_saved)
	Signals.user_refused.connect(_on_user_refused)

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#focuses the name field so the player types a name right away
func prompt_username() -> void:
	_username_field.grab_focus()

#claims the typed username and hides the virtual keyboard, or shows why it is not valid
func _confirm_username() -> void:
	if _is_claiming:
		return
	var typed_username: String = _username_field.text
	_username_field.release_focus()
	_is_claiming = true
	_claim_feedback.text = CHECK_MESSAGE
	if not LeaderboardManager.claim_username(typed_username):
		_is_claiming = false
		_claim_feedback.text = _describe_refused_username(typed_username)

#explains why LeaderboardManager found the username not valid; the checks below mirror its is_valid_username rules
func _describe_refused_username(typed_username: String) -> String:
	if LeaderboardManager.is_valid_username(typed_username):
		return NOT_SAVED_MESSAGE
	var trimmed_username: String = typed_username.strip_edges()
	if trimmed_username.is_empty():
		return EMPTY_MESSAGE
	if trimmed_username.length() > Configs.Leaderboard.username_length:
		return TOO_LONG_MESSAGE % Configs.Leaderboard.username_length
	return INVALID_CHARACTER_MESSAGE

#signal Signals.user_saved => shows the stored name
func _on_user_saved(saved_username: String) -> void:
	_is_claiming = false
	_username_field.text = saved_username
	_claim_feedback.text = SAVED_MESSAGE

#signal Signals.user_refused => shows that the name is taken or could not be saved
func _on_user_refused(refuse_reason: Globals.NameRefuse) -> void:
	_is_claiming = false
	_claim_feedback.text = TAKEN_MESSAGE if refuse_reason == Globals.NameRefuse.Taken else NOT_SAVED_MESSAGE

#signal LineEdit.text_submitted => the keyboard enter/done key confirms the username
func _on_username_submitted(_submitted_text: String) -> void:
	_confirm_username()

#signal LineEdit.text_changed => editing the name clears the previous status
func _on_username_clear(_changed_text: String) -> void:
	_claim_feedback.text = ""

#signal Control.gui_input => a tap on the confirm button confirms the username;
#touch only, since a mouse click also arrives as an emulated touch
func _on_confirm_button(input_event: InputEvent) -> void:
	if input_event is InputEventScreenTouch and input_event.pressed:
		_confirm_username()
