class_name MissionDescriptor

# TODO return more sensible text from some file
func get_mission_description() -> String:
	return "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."


#returns a new voter with a random personality and dialogue variants
func get_voter_descriptor(_index: int) -> VoterDescriptor:
	# Every voter snapshots the currently active dialogue version and random choices.

	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### return DialogueRepository.create_voter_descriptor()
	return DialoguesManager.create_voter_descriptor()
