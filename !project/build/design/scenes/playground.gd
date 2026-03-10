class_name Playground
extends Node2D

@onready var voting_stops : Array = $VotingStops.get_children()
@onready var status_label: Node2D = $Instructions

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func get_stop_at_index(index: int) -> Node2D:
	if index >= 0 and index < voting_stops.size():
		return voting_stops[index]
	return null

func get_total_stops() -> int:
	return voting_stops.size()

func reserve_slot(voter: Character) -> Node2D:
	var available_slots := voting_stops.filter(
		func(slot): return slot.is_free()
	)
	if available_slots.size() == 0:
		return null
	available_slots.sort_custom(
		func(a: Node2D, b: Node2D):
			var dist_a := (voter.global_position - a.global_position).length()
			var dist_b := (voter.global_position - b.global_position).length()
			return dist_a < dist_b
	)
	available_slots[0].occupy(voter)
	return available_slots[0]

func free_slot(voter: Character) -> void:
	var target_slots := voting_stops.filter(
		func(slot: Character): return slot.occupant == voter
	)
	if target_slots.size() == 1:
		target_slots[0].free_up()
