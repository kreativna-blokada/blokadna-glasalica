class_name MissionDescriptor

func get_voter_descriptor(_index: int) -> VoterDescriptor:
	# Every voter snapshots the currently active dialogue version and random choices.
	return DialogueRepository.create_voter_descriptor()
