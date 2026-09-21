class_name MissionDescriptor

var _voters: Array[VoterDescriptor] = []

# TODO parametrize
func _init() -> void:
	_voters.append(VoterDescriptor.new("sample"))
	# _voters.append(VoterDescriptor.new("angry"))

func get_voter_descriptor(index: int) -> VoterDescriptor:
	return _voters[index % len(_voters)]