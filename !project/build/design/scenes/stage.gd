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

#signals
signal queue_count_updated(count: int)
signal stops_occupancy_updated(stop_occupancy: Array)

#private vars
var _max_voter_queue: int = 8
var _selected_voter: Voter = null
var _voters_diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

#broadcast variables
var queued_voters: Array = []

#onready vars
@onready var voters_factory_container: Node2D = $VoterSlots
@onready var queue_spots: Array = $Scenery/VoterSpots.get_children()
@onready var voting_course: Array = $Scenery/VoterStops.get_children()
@onready var voter_loading_position: Node2D = $Scenery/VoterStops/Load

@onready var timer: Timer = $Timer
@onready var info_dialog: InfoDialog = get_parent().get_node("Info Dialog")

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
	_init_signals()

	#loads first voter
	_get_voter(0)

func _process(_delta: float) -> void:
	pass

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
	timer.start()

	_wire_stop_occupancy_updates()

#initializes connections
func _init_signals() -> void:
	if info_dialog:
		info_dialog.dialog_closed.connect(_on_info_dialog_closed)

#initiallizes gameplay
func _init_game() -> void:
	pass

#built-in callback, called authomatically, no signal connection needed
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_handle_start_action()
	elif event.is_action_pressed("select"):
		_handle_select_action()

#release a queueing voter or continue a waiting voter
func _handle_start_action() -> void:
	var selected_voter: Voter = _get_active_selected_voter()
	if not selected_voter: return

	if selected_voter.is_stopping:
		selected_voter.can_continue_voting_course()
	elif selected_voter.is_queueing and queued_voters.has(selected_voter):
		_release_selected_voter(selected_voter)
#todo: review

#handles the 'select' action to cycle through voters
func _handle_select_action() -> void:
	_select_next_voter()
#todo: review

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
	#connects signals for sync queue count and to use dialog
	voter.voter_queued.connect(_on_voter_queued.bind(voter))
	voter.voter_stopped.connect(_on_voter_stopped)

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

#releases a voter from the queue and advances them
func _release_selected_voter(voter: Voter) -> void:
	var freed_spot: Node2D = voter.starting_spot
	if not voter.can_leave_queue(): return

	queued_voters.erase(voter)
	queue_count_updated.emit(queued_voters.size())

	if freed_spot and freed_spot.has_method("free_up"):
		freed_spot.free_up()

	#shuffles the remaining queue after a delay
	await get_tree().create_timer(0.5).timeout
	_update_voters_queue()
#todo: review

#shifts queued voters forward to fill gaps
func _update_voters_queue() -> void:
	var active_voters: Array = queued_voters.duplicate()
	active_voters.sort_custom(func(a, b):
		return queue_spots.find(a.starting_spot) < queue_spots.find(b.starting_spot)
	)

	for voter in active_voters:
		var current_spot: Node2D = voter.starting_spot
		var spot_index: int = queue_spots.find(current_spot)
		if spot_index <= 0: continue

		var spot_ahead: Node2D = queue_spots[spot_index - 1]
		if spot_ahead.is_free():
			current_spot.free_up()
			spot_ahead.occupy(voter)
			voter.assign_queue_spot(spot_ahead)
#todo: review

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

#signal voter.voter_stopped.emit() => show info dialog
func _on_voter_stopped(vote_stop_name: String) -> void:
	if owner.info_dialog:
		info_dialog.show_info(vote_stop_name)

#adds voter to queue and signals queue count
func _on_voter_queued(voter: Voter) -> void:
	queued_voters.append(voter)
	queue_count_updated.emit(queued_voters.size())

#triggers course continuation when dialog closes
func _on_info_dialog_closed() -> void:
	var selected_voter: Voter = _get_active_selected_voter()
	if selected_voter and selected_voter.is_stopping:
		selected_voter.can_continue_voting_course()

#spawning voters signal handler
func _on_timer_timeout() -> void:
	#_increase_spawn_rate()
	if _any_free_queue_spots() and queued_voters.size() < _max_voter_queue:
		_spawn_voters()

	timer.start()       # Restart the X second timer
#Note: spawns enemies after initial time out expires
