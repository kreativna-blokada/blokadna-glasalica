class_name DialogDescriptor

class ChoiceDescriptor:
	var text: String
	var score: int
	var explanation: String
	
	func _init(_text: String, _score: int, _explanation: String):
		text = _text
		score = _score
		explanation = _explanation

enum Speaker {LEFT = 0, RIGHT = 1}

func _init(_text: String, _speaker: Speaker, _choices: Array[ChoiceDescriptor]):
	text = _text
	speaker = _speaker
	choices = _choices

var text: String
var speaker: Speaker
var choices: Array[ChoiceDescriptor]

