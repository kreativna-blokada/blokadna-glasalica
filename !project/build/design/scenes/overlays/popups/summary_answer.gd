class_name SummaryAnswer
extends PanelContainer

#one reviewed answer: a one-line summary while folded, the dialog line and explanation while open

#finger travel, in pixels, past which a press on the header counts as a scroll instead of a tap
const TAP_DEADZONE: float = 20.0

const NUMBER_COLOR: Color = Color("#6B5F55")
const CORRECT_TEXT_COLOR: Color = Color("#3D5A00")
const CORRECT_STATUS_COLOR: Color = Color("#2F4600")
const WRONG_LINE_TEXT_COLOR: Color = Color("#7A1F12")
const WRONG_CARD_TEXT_COLOR: Color = Color("#161616")
const WRONG_STATUS_COLOR: Color = Color("#8E2A1A")
const WRONG_ICON_COLOR: Color = Color("#FFF5E8")

#header metrics while folded (line) and open (card)
const LINE_METRICS: Dictionary[String, Variant] = {
	"margins": Vector4i(20, 10, 20, 10),
	"separation": 18,
	"min_height": 88,
	"icon_box": 48,
	"icon": 26,
	"number_font": 32,
	"number_width": 64,
	"chip_font": 22,
	"chip_width": 160,
	"choice_font": 33,
	"status_font": 27,
}
const CARD_METRICS: Dictionary[String, Variant] = {
	"margins": Vector4i(22, 15, 22, 15),
	"separation": 20,
	"min_height": 94,
	"icon_box": 58,
	"icon": 32,
	"number_font": 33,
	"number_width": 0,
	"chip_font": 24,
	"chip_width": 0,
	"choice_font": 36,
	"status_font": 29,
}

@export_group("Box Styles")
@export var correct_style: StyleBox
@export var wrong_line_style: StyleBox
@export var wrong_card_style: StyleBox
@export_group("Icon Box Styles")
@export var correct_icon_style: StyleBox
@export var wrong_icon_style: StyleBox
#tracked sans for the ZAŠTO: caption leading the explanation
@export var caption_font: Font

var _tracked_choice: GameDescriptor.TrackedChoice
var _is_open: bool = false
var _press_position: Vector2 = Vector2.ZERO

@onready var _header_margin: MarginContainer = %HeaderMargin
@onready var _header: HBoxContainer = %Header
@onready var _icon_box: PanelContainer = %IconBox
@onready var _icon: SummaryIcon = %Icon
@onready var _number_label: Label = %NumberLabel
@onready var _station_chip: PanelContainer = %StationChip
@onready var _station_label: Label = %StationLabel
@onready var _choice_row: HBoxContainer = %ChoiceRow
@onready var _choice_label: Label = %ChoiceLabel
@onready var _arrow_label: Label = %ArrowLabel
@onready var _right_label: Label = %RightLabel
@onready var _choice_row_spacer: Control = %ChoiceRowSpacer
@onready var _status_label: Label = %StatusLabel
@onready var _chevron: SummaryIcon = %Chevron
@onready var _body: MarginContainer = %Body
@onready var _quote_label: Label = %QuoteLabel
@onready var _answers: HBoxContainer = %Answers
@onready var _your_answer_caption: Label = %YourAnswerCaption
@onready var _your_answer_label: Label = %YourAnswerLabel
@onready var _right_answer: PanelContainer = %RightAnswer
@onready var _right_answer_caption: Label = %RightAnswerCaption
@onready var _right_answer_label: Label = %RightAnswerLabel
@onready var _why_label: RichTextLabel = %WhyLabel

func _ready() -> void:
	_header.gui_input.connect(_on_header_gui_input)
	_choice_row.resized.connect(_fit_choice_row)
	_your_answer_caption.text = Literals.SUMMARY_YOUR_ANSWER
	_right_answer_caption.text = Literals.SUMMARY_RIGHT_ANSWER

#fills the answer, folded; call once it is in the tree
func setup(number: int, tracked_choice: GameDescriptor.TrackedChoice) -> void:
	_tracked_choice = tracked_choice
	var is_correct: bool = tracked_choice.is_correct()
	var choice_text: String = tracked_choice.choice_descriptor.text

	_number_label.text = "#%d" % number
	_station_label.text = Literals.SUMMARY_STATION_LABELS.get(tracked_choice.stop_name, tracked_choice.stop_name.to_upper())
	_choice_label.text = choice_text
	#a dialog with only wrong choices has no right answer to show
	var right_text: String = tracked_choice.correct_choice.text if tracked_choice.correct_choice != null else ""
	_right_label.text = right_text
	_status_label.text = Literals.SUMMARY_CORRECT if is_correct else Literals.SUMMARY_WRONG
	_status_label.add_theme_color_override("font_color", CORRECT_STATUS_COLOR if is_correct else WRONG_STATUS_COLOR)
	_icon.shape = SummaryIcon.Shape.CHECK if is_correct else SummaryIcon.Shape.CROSS
	_icon.color = CORRECT_STATUS_COLOR if is_correct else WRONG_ICON_COLOR
	_icon_box.add_theme_stylebox_override("panel", correct_icon_style if is_correct else wrong_icon_style)

	_quote_label.text = "\"%s\"" % tracked_choice.dialog_text
	_your_answer_label.text = choice_text
	_right_answer_label.text = right_text
	_right_answer.visible = tracked_choice.correct_choice != null
	_why_label.clear()
	_why_label.push_font(caption_font, 26)
	_why_label.push_color(CORRECT_STATUS_COLOR if is_correct else WRONG_STATUS_COLOR)
	_why_label.add_text(Literals.SUMMARY_WHY)
	_why_label.pop_all()
	_why_label.add_text(" " + tracked_choice.choice_descriptor.explanation)
	_answers.visible = not is_correct
	_apply_state()

func set_open(is_open: bool) -> void:
	_is_open = is_open
	_apply_state()

#restyles the box and header for the folded or open state
func _apply_state() -> void:
	if _tracked_choice == null:
		return
	var is_correct: bool = _tracked_choice.is_correct()
	var metrics: Dictionary[String, Variant] = CARD_METRICS if _is_open else LINE_METRICS

	var box_style: StyleBox = correct_style
	if not is_correct:
		box_style = wrong_card_style if _is_open else wrong_line_style
	add_theme_stylebox_override("panel", box_style)

	var margins: Vector4i = metrics["margins"]
	_header_margin.add_theme_constant_override("margin_left", margins.x)
	_header_margin.add_theme_constant_override("margin_top", margins.y)
	_header_margin.add_theme_constant_override("margin_right", margins.z)
	_header_margin.add_theme_constant_override("margin_bottom", margins.w)
	_header.add_theme_constant_override("separation", metrics["separation"])
	_header.custom_minimum_size.y = metrics["min_height"] - margins.y - margins.w
	_icon_box.custom_minimum_size = Vector2.ONE * metrics["icon_box"]
	_icon.custom_minimum_size = Vector2.ONE * metrics["icon"]
	_number_label.add_theme_font_size_override("font_size", metrics["number_font"])
	_number_label.custom_minimum_size.x = metrics["number_width"]
	_station_label.add_theme_font_size_override("font_size", metrics["chip_font"])
	_station_chip.custom_minimum_size.x = metrics["chip_width"]
	_status_label.add_theme_font_size_override("font_size", metrics["status_font"])
	for label: Label in [_choice_label, _arrow_label, _right_label]:
		label.add_theme_font_size_override("font_size", metrics["choice_font"])

	var choice_color: Color = CORRECT_TEXT_COLOR
	if not is_correct:
		choice_color = WRONG_CARD_TEXT_COLOR if _is_open else WRONG_LINE_TEXT_COLOR
	_choice_label.add_theme_color_override("font_color", choice_color)
	#the folded wrong line points to the right answer, the open card shows it below
	var shows_right_inline: bool = not is_correct and not _is_open and _tracked_choice.correct_choice != null
	_arrow_label.visible = shows_right_inline
	_right_label.visible = shows_right_inline

	_chevron.turn_degrees = 0.0 if _is_open else -90.0
	_body.visible = _is_open
	_fit_choice_row()

#shares the row between the choice and inline right answer by their text widths, through stretch ratios
#so neither label locks the row's minimum width; both ellipsize once the row runs out of room
func _fit_choice_row() -> void:
	if not _right_label.visible:
		_choice_label.size_flags_stretch_ratio = 1.0
		_choice_row_spacer.visible = false
		return

	var available: float = maxf(_choice_row.size.x - _get_text_width(_arrow_label), 0.0)
	var choice_width: float = _get_text_width(_choice_label)
	var right_width: float = _get_text_width(_right_label)
	if choice_width + right_width > available:
		right_width = minf(right_width, maxf(available / 2.0, available - choice_width))
		choice_width = available - right_width
	var spare_width: float = available - choice_width - right_width
	_choice_label.size_flags_stretch_ratio = maxf(choice_width, 1.0)
	_right_label.size_flags_stretch_ratio = maxf(right_width, 1.0)
	_choice_row_spacer.size_flags_stretch_ratio = maxf(spare_width, 1.0)
	_choice_row_spacer.visible = spare_width >= 1.0

func _get_text_width(label: Label) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	return ceilf(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

#a tap toggles the answer; a press that drags the list along does not
func _on_header_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_press_position = event.global_position
	elif event.global_position.distance_to(_press_position) < TAP_DEADZONE:
		set_open(not _is_open)
