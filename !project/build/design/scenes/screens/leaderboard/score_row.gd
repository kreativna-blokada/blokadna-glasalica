##
# Copyright (C) 2026 Blokadna Igra (kreativna.blokada@proton.me)
##
#description     : One leaderboard row: rank, username and score; podium rows wear their medal, the player's row is purple
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name ScoreRow
extends PanelContainer

const OWN_FRAME_COLOR: Color = Color(0.419608, 0.0392157, 0.368627, 1)
const OWN_FRAME_WIDTH: float = 6.0
#gap between the row edge and the player's frame around a podium row
const OWN_FRAME_GAP: float = 3.0

#podium rows only: row and rank badge style for the 1st, 2nd and 3rd place
@export var place_styles: Array[StyleBox] = []
@export var badge_styles: Array[StyleBox] = []
#plain rows only: the player's row style and text color
@export var own_style: StyleBox
@export var own_text_color: Color = Color.WHITE

#private vars
var _has_own_frame: bool = false

#onready vars
@onready var _rank_label: Label = %RankLabel
@onready var _name_label: Label = %NameLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _badge: PanelContainer = get_node_or_null("%Badge")

#fills the row; call once in the tree; a podium row frames the player's row, a plain row fills it purple;
#a rank caption replaces the rank, e.g. for the player's own row below the best scores
func setup(entry_rank: int, entry_username: String, entry_score: int, is_own_standing: bool, rank_caption: String = "") -> void:
	_name_label.text = entry_username
	_score_label.text = group_score_digits(entry_score)

	if _badge != null:
		var place_index: int = clampi(entry_rank - 1, 0, place_styles.size() - 1)
		_rank_label.text = str(entry_rank)
		add_theme_stylebox_override("panel", place_styles[place_index])
		_badge.add_theme_stylebox_override("panel", badge_styles[place_index])
		if is_own_standing:
			_name_label.add_theme_color_override("font_color", OWN_FRAME_COLOR)
		_has_own_frame = is_own_standing
		queue_redraw()
		return

	_rank_label.text = rank_caption if not rank_caption.is_empty() else Literals.BOARD_RANK_CAPTION % entry_rank
	if is_own_standing:
		add_theme_stylebox_override("panel", own_style)
		for row_label: Label in [_rank_label, _name_label, _score_label]:
			row_label.add_theme_color_override("font_color", own_text_color)

func _draw() -> void:
	if _has_own_frame:
		var frame_rect: Rect2 = Rect2(Vector2.ZERO, size).grow(OWN_FRAME_GAP + OWN_FRAME_WIDTH / 2.0)
		draw_rect(frame_rect, OWN_FRAME_COLOR, false, OWN_FRAME_WIDTH)

#writes the full score with a dot between each group of three digits
static func group_score_digits(entry_score: int) -> String:
	var score_digits: String = str(absi(entry_score))
	var grouped_digits: String = ""
	while score_digits.length() > 3:
		grouped_digits = "." + score_digits.right(3) + grouped_digits
		score_digits = score_digits.left(-3)
	return ("-" if entry_score < 0 else "") + score_digits + grouped_digits
