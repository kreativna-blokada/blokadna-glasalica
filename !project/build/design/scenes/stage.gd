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
var _active_voters: Array = []
var _max_voter_queue: int = 4
var _selected_voter: Voter = null

#broadcast variables
var _voters_diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

#onready vars
@onready var voters_factory_container: Node2D = $VoterSlots
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
	if event.is_action_pressed("start"):
		var selected: Voter = _get_selected_voter()
		if selected:
			if selected._is_waiting:
				selected.continue_course()
			elif selected._is_queueing and _active_voters.has(selected):
				_release_selected_voter(selected)
	if event.is_action_pressed("select"):
		_select_next_voter()

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

#loads voters with random setups
func _spawn_voters() -> void:
	var index: int = _rand.randi() % _voters_diversity

	_get_voter(index)

#gets voter from the factory and sets it up for the voting process
func _get_voter(_index: int) -> Node:
	if voters_factory_container and voters_factory_container.has_method("load_voter"):
		var voter = voters_factory_container.load_voter(_index)
		voters_factory_container.add_child(voter)

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

func _get_selectable_voters() -> Array:
	var voters: Array = get_tree().get_nodes_in_group("actor")
	var selectable: Array = []
	for voter in voters:
		if voter is Voter and (voter._is_waiting or voter._is_queueing):
			selectable.append(voter)
	selectable.sort_custom(func(a: Voter, b: Voter):
		if a._is_queueing and b._is_queueing:
			return queue_spots.find(a.starting_spot) < queue_spots.find(b.starting_spot)
		if a._is_queueing:
			return false
		if b._is_queueing:
			return true
		return a._voting_course_pointer > b._voting_course_pointer
	)
	return selectable

func _select_next_voter() -> void:
	var selectable: Array = _get_selectable_voters()
	if selectable.is_empty():
		return
	if _selected_voter and is_instance_valid(_selected_voter):
		_selected_voter.character_texture.material.set_shader_parameter("enabled", false)
	var current_index: int = selectable.find(_selected_voter)
	var next_index: int = (current_index + 1) % selectable.size()
	_selected_voter = selectable[next_index]
	_selected_voter.character_texture.material.set_shader_parameter("enabled", true)

func _on_voters_entering(voter: Voter) -> void:
	_active_voters.append(voter)

func _get_selected_voter() -> Voter:
	if _selected_voter and is_instance_valid(_selected_voter):
		return _selected_voter
	return null

func _release_selected_voter(voter: Voter) -> void:
	var freed_spot: Node2D = voter.starting_spot
	if not voter.release_from_queue():
		return
	_active_voters.erase(voter)
	if freed_spot and freed_spot.has_method("free_up"):
		freed_spot.free_up()
	await get_tree().create_timer(0.5).timeout
	_update_voters_queue()
#todo: cleanup

func _update_voters_queue() -> void:
	var active_voters_sorting: Array = _active_voters.duplicate()
	active_voters_sorting.sort_custom(func(first_voter: Voter, second_voter: Voter):
		return queue_spots.find(first_voter.starting_spot) < queue_spots.find(second_voter.starting_spot)
	)
	for voter in active_voters_sorting:
		var voter_init_spot: Node2D = voter.starting_spot
		var queue_spot_index: int = queue_spots.find(voter_init_spot)
		if queue_spot_index > 0:
			var spot_ahead: Node2D = queue_spots[queue_spot_index - 1]
			if spot_ahead.is_free():
				voter_init_spot.free_up()
				spot_ahead.occupy(voter)
				voter.move_to_queue_spot(spot_ahead)
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
	if _has_free_vote_spot() and _active_voters.size() < _max_voter_queue:
		_spawn_voters()
		
	_timer.start()       # Restart the X second timer
#Note: spawns enemies after initial time out expires
