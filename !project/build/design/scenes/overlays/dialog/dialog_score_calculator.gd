class_name DialogScoreCalculator

#returns the answer score in full, however long the answer took
static func calculate_score(choice_descriptor: DialogDescriptor.ChoiceDescriptor, _answer_time: float) -> float:
	return choice_descriptor.score

#returns points in thousands with a k, or the plain number below a thousand
static func format_points(points: float) -> String:
	if absf(points) < 1000.0:
		return "%d" % roundi(points)
	return ("%.1f" % (points / 1000.0)).trim_suffix(".0") + "k"
