##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Rewards screen in the leaderboard design with a badge box per top list, bordered and in stronger colours when its tab is selected
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name RewardsScreen
extends Control

#exported vars
@export var box_style: StyleBox
@export var selected_box_style: StyleBox

#onready vars
@onready var _title_label: Label = %TitleLabel
@onready var _board_tabs: Dictionary[Globals.ScoreBoard, Button] = {
	Globals.ScoreBoard.Daily: %DailyTab,
	Globals.ScoreBoard.Weekly: %WeeklyTab,
	Globals.ScoreBoard.Total: %TotalTab,
}
@onready var _board_boxes: Dictionary[Globals.ScoreBoard, PanelContainer] = {
	Globals.ScoreBoard.Daily: %DailyBox,
	Globals.ScoreBoard.Weekly: %WeeklyBox,
	Globals.ScoreBoard.Total: %TotalBox,
}
@onready var _board_vivid_overlays: Dictionary[Globals.ScoreBoard, ColorRect] = {
	Globals.ScoreBoard.Daily: %DailyVividOverlay,
	Globals.ScoreBoard.Weekly: %WeeklyVividOverlay,
	Globals.ScoreBoard.Total: %TotalVividOverlay,
}
@onready var _rules_text: RichTextLabel = %RulesText
@onready var _back_button: Button = %BackButton

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_title_label.text = Literals.BOARD_REWARDS
	_rules_text.text = Literals.REWARDS_RULES_MESSAGE
	_back_button.text = Literals.BOARD_BACK
	for score_board in _board_tabs:
		_board_tabs[score_board].text = Literals.BOARD_TAB_CAPTIONS[score_board]
		_board_tabs[score_board].toggled.connect(_on_board_tab_toggled.bind(score_board))

	_back_button.pressed.connect(_on_back_pressed)

	_board_tabs[Globals.ScoreBoard.Daily].set_pressed_no_signal(true)
	_select_board_box(Globals.ScoreBoard.Daily)

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

#borders the selected board's badge box and strengthens its colours
func _select_board_box(selected_board: Globals.ScoreBoard) -> void:
	for score_board in _board_boxes:
		var is_selected := score_board == selected_board
		_board_boxes[score_board].add_theme_stylebox_override("panel", selected_box_style if is_selected else box_style)
		_board_vivid_overlays[score_board].visible = is_selected

#signal Button.toggled => a newly selected tab sounds like the leaderboard tabs and borders its badge box
func _on_board_tab_toggled(is_toggled_on: bool, score_board: Globals.ScoreBoard) -> void:
	if is_toggled_on:
		SoundManager.play_stinger(Globals.Sound.MenuSelect)
		_select_board_box(score_board)

#signal Button.pressed => returns to the leaderboard
func _on_back_pressed() -> void:
	visible = false
