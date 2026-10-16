class_name GameSummary
extends Control

signal continue_pressed

const ANSWER_SCENE: PackedScene = preload("res://!project/build/design/scenes/overlays/popups/summary_answer.tscn")

@onready var _title_label: Label = %TitleLabel
@onready var _percent_label: Label = %PercentLabel
@onready var _score_bar: SummaryScoreBar = %ScoreBar
@onready var _answers: VBoxContainer = %Answers
@onready var _continue_button: Button = %ContinueButton

func _ready() -> void:
	_title_label.text = Literals.SUMMARY_TITLE
	_continue_button.text = Literals.SUMMARY_CONTINUE
	_continue_button.pressed.connect(continue_pressed.emit)

#lists the run's answers in the order they were given, wrong ones already open; call once in the tree
func set_choices(choices: Array[GameDescriptor.TrackedChoice]) -> void:
	for child in _answers.get_children():
		child.queue_free()

	var correct_count: int = 0
	for i in choices.size():
		var tracked_choice: GameDescriptor.TrackedChoice = choices[i]
		var answer: SummaryAnswer = ANSWER_SCENE.instantiate() as SummaryAnswer
		_answers.add_child(answer)
		answer.setup(i + 1, tracked_choice)
		answer.set_open(not tracked_choice.is_correct())
		if tracked_choice.is_correct():
			correct_count += 1

	var percent: int = roundi(100.0 * correct_count / choices.size()) if not choices.is_empty() else 0
	_percent_label.text = "%d%%" % percent
	_score_bar.set_score(correct_count, choices.size())

