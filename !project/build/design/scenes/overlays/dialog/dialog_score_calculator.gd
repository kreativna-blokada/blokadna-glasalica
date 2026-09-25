class_name DialogScoreCalculator

static func calculate_score(choice_descriptor: DialogDescriptor.ChoiceDescriptor, answer_time: float) -> float:
	if choice_descriptor.score < 0:
		return choice_descriptor.score
	
	# dampen score if it's a positive answer
	return exp(-answer_time * 0.5) * choice_descriptor.score