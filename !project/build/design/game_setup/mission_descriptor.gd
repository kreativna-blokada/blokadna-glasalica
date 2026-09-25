class_name MissionDescriptor

#returns a new voter with a random personality and dialogue variants
func get_voter_descriptor(_index: int) -> VoterDescriptor:
	# Every voter snapshots the currently active dialogue version and random choices.

	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### return DialogueRepository.create_voter_descriptor()
	return DialoguesManager.create_voter_descriptor()
