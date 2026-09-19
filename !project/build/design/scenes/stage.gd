##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master game stage runner
#maintainer      : Zeljko Vulovic
#version         : 1.1
#===============================================================================
class_name Stage
extends Node2D

#signals
signal queue_count_updated(count: int)
signal stops_occupancy_updated(stops_occupancy_flags: Array)

#broadcast vars
var queued_voters: Array = []

#private vars
var _selected_voter: Voter = null
var _max_voter_queue: int = 8
var _voters_diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var _is_queue_consolidating: bool = false

#onready vars
@onready var voters_factory_container: Node2D = $VoterSlots
@onready var queue_spots: Array = $Scenery/VoterSpots.get_children()
@onready var voting_course: Array = $Scenery/VoterStops.get_children()
@onready var voter_loading_position: Node2D = $Scenery/VoterStops/Load

@onready var timer: Timer = $Timer

#CALLBACKS
# ██████╗ █████╗ ██╗     ██╗     ██████╗  █████╗  ██████╗██╗  ██╗███████╗
#██╔════╝██╔══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝
#██║     ███████║██║     ██║     ██████╔╝███████║██║     █████╔╝ ███████╗
#██║     ██╔══██║██║     ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║
#╚██████╗██║  ██║███████╗███████╗██████╔╝██║  ██║╚██████╗██║  ██╗███████║
# ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝

func _ready() -> void:
	_init_vars()
	_init_nodes()

	#loads first voter
	_get_voter(0)

func _process(_delta: float) -> void:
	pass

#built-in callback, called authomatically
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_handle_start_action()
	elif event.is_action_pressed("select"):
		_handle_select_action()
	elif event.is_action_pressed("next"):
		# print_debug("next")
		_handle_next_action()

#initiallizes variables
func _init_vars() -> void:
	_rand.randomize()
	_voters_diversity = Globals.VoterFactory.size()#+1

#initiallizes structures
func _init_nodes() -> void:
	timer.start()

	_wire_stop_occupancy_updates()

#initiallizes gameplay
func _init_game() -> void:
	pass

#release a queueing voter or continue a waiting voter
func _handle_start_action() -> void:
	var selected_voter: Voter = _get_active_selected_voter()
	if not selected_voter: return

	if selected_voter.is_stopping:
		selected_voter.can_continue_voting_course()
	elif selected_voter.is_queueing and queued_voters.has(selected_voter):
		_dequeue_voter(selected_voter)

func _handle_next_action() -> void:
	var selected_voter: Voter = _get_active_selected_voter()
	if not selected_voter:
		_select_next_voter()
		selected_voter = _get_active_selected_voter()

	if selected_voter.is_stopping:
		selected_voter.can_continue_voting_course()
	elif selected_voter.is_queueing and queued_voters.has(selected_voter):
		_dequeue_voter(selected_voter)


#cycles (outlines) through voters
func _handle_select_action() -> void:
	_select_next_voter()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#updates the flow indicators, or by connecting to each voting stop's signal
#the stage can detect when a voter has physically reached or left a station,
#it then performs a snapshot of the course, checking if each stop is_free()
#and it broadcasts this occupancy map to update the progress flow indicators
func _wire_stop_occupancy_updates() -> void:
	#scans stops where voters supposed to stay
	for voting_stop in voting_course:
		if voting_stop.has_signal("occupancy_updated"):
			#captures a snapshot of the room when voter arrives or leaves
			voting_stop.occupancy_updated.connect(
				#broadcast stops occupancy update
				func(): stops_occupancy_updated.emit(
					#maps the state of the voting course into a boolean array
					voting_course.map(func(stop): return not stop.is_free())
				)
			)

#loads voters w/ random setups
func _spawn_voters() -> void:
	var index: int = _rand.randi() % _voters_diversity
	_get_voter(index)

#gets and sets a voter from the factory
func _get_voter(index: int) -> Voter:
	if not voters_factory_container or not voters_factory_container.has_method("load_voter"):
		push_error("[STAGE] Voter factory container is missing or invalid!")
		return null

	#creates an instance using factory script, adds it to the scene
	var voter: Voter = voters_factory_container.load_voter(index)
	voters_factory_container.add_child(voter)

	voter.position = voter_loading_position.global_position
	var walking_course: Array = get_voting_course(voter)
	#assigns movement path for a loaded voter
	voter.set_walking_course(walking_course)
	#connects signal for syncing the queue count
	voter.voter_queued.connect(_on_voter_queued.bind(voter))

	return voter

#defines the voting process route for voter
func get_voting_course(voter: Voter) -> Array:
	#starting course with the voter loading stop
	var walk_course: Array = [voter_loading_position]

	var queue_place: Node2D = _find_first_queue_spot()
	if queue_place:
		queue_place.occupy(voter)
		#infiltrating queue stop into the voter stops
		walk_course.append(queue_place)

	#adds rest of the course, excluding loading stop
	walk_course.append_array(voting_course.slice(1))
	return walk_course

#checks if any queue spot is available
func _any_free_queue_spots() -> bool:
	return queue_spots.any(func(spot): return spot.is_free())

#returns first available queue spot
func _find_first_queue_spot() -> Node2D:
	for spot in queue_spots:
		if spot.is_free(): return spot
	return null

#returns (validates) currently selected voter
func _get_active_selected_voter() -> Voter:
	if _selected_voter and is_instance_valid(_selected_voter):
		return _selected_voter
	return null

#returns the voter currently waiting at a specific voting stop
func get_stopped_voter_at_stop(stop_index: int) -> Voter:
	if stop_index < 0 or stop_index >= voting_course.size():
		return null

	var target_stop: VotingStop = voting_course[stop_index]
	for child in voters_factory_container.get_children():
		var voter: Voter = child as Voter
		if voter == null or not voter.is_stopping:
			continue
		if voter.voting_course_pointer < 0 or voter.voting_course_pointer >= voter.voting_course.size():
			continue
		if voter.voting_course[voter.voting_course_pointer] == target_stop:
			return voter
	return null

#manages voter release and queue consolidation
func _dequeue_voter(voter: Voter) -> void:
	#can_leave_queue() clears starting_spot, so retain it before advancing the voter
	var queue_spot: VotingStop = voter.starting_spot
	if not voter.can_leave_queue(): return

	#removes voter from queue
	queued_voters.erase(voter)
	#signals queue count (_on_queue_count_updated)
	queue_count_updated.emit(queued_voters.size())

	#removes voter from the spot, makes position vacant
	if queue_spot and queue_spot.has_method("free_up"):
		queue_spot.free_up()

	#shuffles the remaining queue after a delay
	_is_queue_consolidating = true
	await get_tree().create_timer(0.5).timeout
	_shift_voters_forward()
	_is_queue_consolidating = false

#forward movment for waiting voters
func _shift_voters_forward() -> void:
	#copy to prevent array mutations during iteration
	var queuing_voters: Array = queued_voters.duplicate()
	#sorts by queue position to ensure a shift sequence
	queuing_voters.sort_custom(func(primary, secondary):
		return queue_spots.find(primary.starting_spot) < queue_spots.find(secondary.starting_spot)
	)

	#iterates for step-forward
	for voter in queuing_voters:
		#voters know their queue (starting) position
		var queue_spot: Node2D = voter.starting_spot
		var spot_index: int = queue_spots.find(queue_spot)
		#voter is already at the front of the queue line
		if spot_index <= 0: continue

		#target position is the next from voters' queue position
		var target_queue_spot: Node2D = queue_spots[spot_index - 1]
		if target_queue_spot.is_free():
			queue_spot.free_up()

			#marks target spot as occupied
			target_queue_spot.occupy(voter)
			#updates voter position in the queue
			voter.assign_queue_spot(target_queue_spot)

#cycles to next available voter
func _select_next_voter() -> void:
	var selectable_voters: Array = _get_selectable_voters()
	if selectable_voters.is_empty(): return

	#resets voter outline, or deselects (previously) selected voter
	if _selected_voter and is_instance_valid(_selected_voter):
		_set_voter_outline(_selected_voter, false)

	var selected_voter_index: int = selectable_voters.find(_selected_voter)
	var next_voter_index: int = (selected_voter_index + 1) % selectable_voters.size()
	_selected_voter = selectable_voters[next_voter_index]
	#sets voter outline, or selects currently available voter
	_set_voter_outline(_selected_voter, true)

#gets all voters available for selection
func _get_selectable_voters() -> Array:
	var selectable_voters: Array = voters_factory_container.get_children().filter(
		func(voter): return voter is Voter and (voter.is_stopping or voter.is_queueing)
	)

	selectable_voters.sort_custom(func(primary, secondary):
		if primary.is_queueing != secondary.is_queueing:
			#prioritize waiting over queueing
			return secondary.is_queueing
		if primary.is_queueing:
			return queue_spots.find(primary.starting_spot) < queue_spots.find(secondary.starting_spot)
		return primary.voting_course_pointer > secondary.voting_course_pointer
	)
	return selectable_voters

#toggles the visual outline for a previously selected voter
func _set_voter_outline(voter: Voter, is_selected: bool) -> void:
	if voter.character_texture and voter.character_texture.material:
		voter.character_texture.material.set_shader_parameter("enabled_outline", is_selected)

#SIGNALS
#███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
#██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
#███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
#╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
#███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
#╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝

#adds voter to queue and signals queue count
func _on_voter_queued(voter: Voter) -> void:
	queued_voters.append(voter)
	queue_count_updated.emit(queued_voters.size())

#spawning voters signal handler
func _on_timer_timeout() -> void:
	if not _is_queue_consolidating and _any_free_queue_spots() and queued_voters.size() < _max_voter_queue:
		_spawn_voters()

	timer.start()       # Restart the X second timer
