class_name DialogDescriptor

class ChoiceDescriptor:
	var text: String
	var score: int
	
	func _init(_text: String, _score: int):
		text = _text
		score = _score

enum Speaker {LEFT = 0, RIGHT = 1}

func _init(_text: String, _speaker: Speaker, _choices: Array[ChoiceDescriptor]):
	text = _text
	speaker = _speaker
	choices = _choices

var text: String
var speaker: Speaker
var choices: Array[ChoiceDescriptor]

