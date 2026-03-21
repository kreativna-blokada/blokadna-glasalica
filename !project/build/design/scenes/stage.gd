##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master game stage runner
#author          : Zeljko Vulovic
#date            : 20260110
#version         : 1.0
#===============================================================================
class_name Stage
extends Node2D

#data containers
var _voters_factory: Node = null

var _voters_entering: Array = []
var _max_voter_queue: int = 4

#broadcast variables
var _voters_diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

#onready vars
@onready var voters_container: Node2D = $VoterSlots
@onready var queue_spots: Array = $VoterSpots.get_children()
@onready var voting_course: Array = $VoterStops.get_children()
@onready var voter_loading_position: Node2D = $VoterStops/Load

@onready var _timer: Timer = $Timer

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_vars()
	_init_nodes()

	_get_voter( 0 )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#built-in callback, called authomatically, no signal connection needed
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") and _voters_entering.size() > 0:
		_release_first_voter()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#initiallizes variables
func _init_vars() -> void:
	_rand.randomize()

	_voters_factory = voters_container
	_voters_diversity = Globals.VoterFactory.size()#+1
	#_timer.start()			# if autostart isn't selected, will start the timer
	#spawn_voters(_spawn_rate)# do this or else it will take X secs before spawn

	#init loading voters peculiarity
	#_timer.set_wait_time(_spawn_cycle_range_max)
	#_timer.start()

#initiallizes structures
func _init_nodes() -> void:
	#init loading voters peculiarity
	#_load_spawn_vars()
	##_timer.set_wait_time(_spawn_cycle_range_max)
	_timer.start()

#initiallizes gameplay
func _init_game() -> void:
	pass

#loads voters with random setups
func _spawn_voters() -> void:
	var index: int = _rand.randi() % _voters_diversity

	_get_voter(index)

#gets voter from the factory and sets it up for the voting process
func _get_voter(_index: int) -> Node:
	if _voters_factory and _voters_factory.has_method("load_voter"):
		var voter = _voters_factory.load_voter(_index)
		voters_container.add_child(voter)

		voter.position = voter_loading_position.global_position
		var walking_course: Array = get_voting_course(voter)
		voter.set_walking_course(walking_course)
		voter.queue_place_taken.connect(_on_voters_entering.bind(voter))

		print("[STAGE] Successfully fetched voter of index: ", _index)

		return voter
	else:
		push_error("[STAGE] critical: instance is null or missing voter.gd script!")
		return null

#defines the voting process route for voters
func get_voting_course(voter: Voter) -> Array:
	var walking_course: Array = [voter_loading_position]

	var queue_place: Node2D = _find_queue_spot()
	if queue_place:
		queue_place.occupy(voter)
		walking_course.append(queue_place)

	walking_course.append_array(voting_course.slice(1))

	return walking_course

func get_vote_stop(index: int) -> Node2D:
	if index >= 0 and index < voting_course.size():
		return voting_course[index]
	return null

func get_total_stops() -> int:
	return voting_course.size()

func reserve_slot(voter: Character) -> Node2D:
	var available_slots := voting_course.filter(
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
	var target_slots := voting_course.filter(
		func(slot: Character): return slot.occupant == voter
	)
	if target_slots.size() == 1:
		target_slots[0].free_up()

func _has_free_vote_spot() -> bool:
	for spot in queue_spots:
		if spot.is_free():
			return true
	return false

#returns the first free queue spot
func _find_queue_spot() -> Node2D:
	for spot in queue_spots:
		if spot.is_free():
			return spot
	return null

#returns the last free queue spot
func _find_last_free_spot() -> Node2D:
	var free_spot: Node2D = null
	for spot in queue_spots:
		if spot.is_free():
			free_spot = spot
	return free_spot

func _on_voters_entering(voter: Voter) -> void:
	_voters_entering.append(voter)

func _release_first_voter() -> void:
	var first: Voter = _voters_entering.pop_front()
	var freed_spot: Node2D = first.queue_spot
	if freed_spot and freed_spot.has_method("free_up"):
		freed_spot.free_up()
	first.release_from_queue()
	await get_tree().create_timer(0.5).timeout
	_shuffle_queue()
#todo: cleanup

func _shuffle_queue() -> void:
	var sorted_queue: Array = _voters_entering.duplicate()
	sorted_queue.sort_custom(func(a: Voter, b: Voter):
		return queue_spots.find(a.queue_spot) < queue_spots.find(b.queue_spot)
	)
	for voter in sorted_queue:
		var current_spot: Node2D = voter.queue_spot
		var spot_index: int = queue_spots.find(current_spot)
		if spot_index > 0:
			var ahead_spot: Node2D = queue_spots[spot_index - 1]
			if ahead_spot.is_free():
				current_spot.free_up()
				ahead_spot.occupy(voter)
				voter.move_to_queue_spot(ahead_spot)
#todo: cleanup

#SIGNALS
#███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
#██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
#███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
#╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
#███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
#╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝

func _on_timer_timeout() -> void:
	#_increase_spawn_rate()
	if _has_free_vote_spot() and _voters_entering.size() < _max_voter_queue:
		_spawn_voters()
		
	_timer.start()       # Restart the X second timer
#Note: spawns enemies after initial time out expires
