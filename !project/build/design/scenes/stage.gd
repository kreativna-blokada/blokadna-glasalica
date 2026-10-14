##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Master game stage runner
#maintainer      : Zeljko
#version         : 1.1
#===============================================================================
class_name Stage
extends Node2D

#signals
signal queue_count_updated(count: int)
signal stops_occupancy_updated(stops_occupancy_flags: Array)
signal next_voter_availability_updated(is_available: bool)
signal dialogue_requested(voter: Voter, stop_name: String)
signal room_voter_stopped(station_number: int)

#broadcast vars
var queued_voters: Array = []

#private vars
var _selected_voter: Voter = null
var _voter_in_room: Voter = null
var _max_voter_queue: int = 8
var _voter_factory_indices: Array[int] = []
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var _is_queue_consolidating: bool = false
#false while a dialog is open, so Select and Initiate neither outline nor move voters
var _is_voter_control_enabled: bool = true
#voter Initiate was pressed on just before it stopped; its dialog opens once it stops
var _voter_awaiting_dialogue: Voter = null
#true on the challenge difficulty: Initiate releases any selected queued voter, even while others walk the voting room
var _is_room_shared: bool = false
var _mission_descriptor: MissionDescriptor = GameManager.get_mission_descriptor()


#onready vars
@onready var voters_factory: VotersFactory = $VoterSlots
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

func init(mission_descriptor: MissionDescriptor) -> void:
	_mission_descriptor = mission_descriptor


func _ready() -> void:
	_init_vars()
	_init_nodes()

#starts loading voters, the first one immediately, the rest on timer
func start_spawning() -> void:
	#loads first voter
	_get_voter(0)
	timer.start()

func _process(_delta: float) -> void:
	pass

#built-in callback, called authomatically
func _unhandled_input(event: InputEvent) -> void:
	if _is_voter_control_enabled and event.is_action_pressed("initiate"):
		_handle_start_action()
	elif _is_voter_control_enabled and event.is_action_pressed("select"):
		_handle_select_action()
	elif event.is_action_pressed("next"):
		# print_debug("next")
		_handle_next_action()

#initiallizes variables
func _init_vars() -> void:
	_rand.randomize()
	_is_room_shared = GameManager.get_game_descriptor().is_challenge()
	for factory_index in Globals.VoterFactory:
		var texture_path: String = Globals.VoterFactory[factory_index]["Texture2D"]
		if ResourceLoader.exists(texture_path, "Texture2D"):
			_voter_factory_indices.append(int(factory_index))

	if _voter_factory_indices.is_empty():
		push_error("[STAGE] No voter textures are available!")

#initiallizes structures
func _init_nodes() -> void:
	_wire_stop_occupancy_updates()

#initiallizes gameplay
func _init_game() -> void:
	pass

#release a queueing voter, or open the dialog of a stopped voter
func _handle_start_action() -> void:
	var selected_voter: Voter = _get_active_selected_voter()
	if not selected_voter: return

	if selected_voter.is_stopping:
		# selected_voter.can_continue_voting_course()
		var stop_name: String = str(selected_voter.voting_course[selected_voter.voting_course_pointer].name)
		dialogue_requested.emit(selected_voter, stop_name)
	elif selected_voter.is_arriving(Configs.ClassicalControllers["dialog_opening_buffer"]):
		_voter_awaiting_dialogue = selected_voter
	elif selected_voter.is_queueing and queued_voters.has(selected_voter) and _is_room_shared:
		_dequeue_voter(selected_voter)
	elif selected_voter.is_queueing and queued_voters.has(selected_voter):
		_handle_next_action()

func _handle_next_action() -> void:
	if not is_next_voter_available():
		return

	_dequeue_voter(_get_front_queue_voter())

#turns Select and Initiate off while a dialog is open, back on when it closes
func set_voter_control_enabled(is_enabled: bool) -> void:
	_is_voter_control_enabled = is_enabled

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
	if _voter_factory_indices.is_empty():
		return
	var random_index: int = _rand.randi_range(0, _voter_factory_indices.size() - 1)
	var index: int = _voter_factory_indices[random_index]
	_get_voter(index)

#gets and sets a voter from the factory
func _get_voter(index: int) -> Voter:
	if not voters_factory:
		push_error("[STAGE] Voter factory container is missing or invalid!")
		return null

	#creates an instance using factory script, adds it to the scene
	var voter: Voter = voters_factory.load_voter(index)
	voters_factory.add_child(voter)

	voter.position = voter_loading_position.global_position
	var walking_course: Array = get_voting_course(voter)
	#assigns movement path for a loaded voter
	voter.set_walking_course(walking_course)
	#connects signal for syncing the queue count
	voter.voter_queued.connect(_on_voter_queued.bind(voter))
	voter.course_point_reached.connect(_on_voter_course_point_reached.bind(voter))
	voter.voter_stopped.connect(_on_voter_stopped.bind(voter))
	voter.init(_mission_descriptor.get_voter_descriptor(index))

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

#spawns a voter at once when the room voter is far along the course and nobody waits or walks to the queue
func _refill_empty_queue(stopped_voter: Voter) -> void:
	if stopped_voter != _voter_in_room or _has_incoming_voter() or not _any_free_queue_spots():
		return
	if _get_station_number(stopped_voter) >= Configs.Round["queue_refill_station"]:
		_spawn_voters()

#reports whether any voter is queueing or still walking to the queue
func _has_incoming_voter() -> bool:
	return voters_factory.get_children().any(
		func(voter): return voter is Voter and voter.voting_course_pointer <= 1
	)

#counts the stations the voter has reached, its current one included
func _get_station_number(voter: Voter) -> int:
	var reached_course: Array = voter.voting_course.slice(0, voter.voting_course_pointer + 1)
	return reached_course.filter(func(stop): return stop is VotingStop and stop.is_stop).size()

#returns (validates) currently selected voter
func _get_active_selected_voter() -> Voter:
	if _selected_voter and is_instance_valid(_selected_voter):
		return _selected_voter
	return null

#reports whether the front voter can enter an empty voting room
func is_next_voter_available() -> bool:
	return not _has_voter_in_room() and _get_front_queue_voter() != null

#returns the queued voter closest to the room entrance
func _get_front_queue_voter() -> Voter:
	var front_voter: Voter = null
	var front_spot_index: int = queue_spots.size()

	for queued_voter in queued_voters:
		var voter: Voter = queued_voter as Voter
		if voter == null or not is_instance_valid(voter) or not voter.is_queueing:
			continue
		var spot_index: int = queue_spots.find(voter.starting_spot)
		if spot_index >= 0 and spot_index < front_spot_index:
			front_voter = voter
			front_spot_index = spot_index

	return front_voter

func _has_voter_in_room() -> bool:
	return _voter_in_room != null and is_instance_valid(_voter_in_room)

#returns the voter currently waiting at a specific voting stop
func get_stopped_voter_at_stop(stop_index: int) -> Voter:
	if stop_index < 0 or stop_index >= voting_course.size():
		return null

	var target_stop: VotingStop = voting_course[stop_index]
	for child in voters_factory.get_children():
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
	if voter == null: return
	if not _is_room_shared and (_has_voter_in_room() or voter != _get_front_queue_voter()):
		return

	#can_leave_queue() clears starting_spot, so retain it before advancing the voter
	var queue_spot: VotingStop = voter.starting_spot
	if not voter.can_leave_queue(): return

	#a shared room keeps tracking its earliest voter, the ones following it walk in untracked
	if not _has_voter_in_room():
		_voter_in_room = voter
		#fallback for voters removed before reaching the normal Exit point
		voter.tree_exited.connect(_on_room_voter_exited.bind(voter), CONNECT_ONE_SHOT)
		next_voter_availability_updated.emit(false)

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
	var selectable_voters: Array = voters_factory.get_children().filter(
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
	next_voter_availability_updated.emit(is_next_voter_available())

#unlocks the next voter when the current voter reaches the room exit
func _on_voter_course_point_reached(point_name: StringName, voter: Voter) -> void:
	if point_name == &"Exit":
		_release_room_voter(voter)

#opens the dialog asked for while the voter was about to stop, otherwise reports the room voter's station
func _on_voter_stopped(stop_name: String, voter: Voter) -> void:
	_refill_empty_queue(voter)
	if voter != _voter_awaiting_dialogue:
		if voter == _voter_in_room:
			room_voter_stopped.emit(_get_station_number(voter))
		return
	_voter_awaiting_dialogue = null
	dialogue_requested.emit(voter, stop_name)

#fallback for a room voter removed before reaching Exit
func _on_room_voter_exited(voter: Voter) -> void:
	_release_room_voter(voter)

func _release_room_voter(voter: Voter) -> void:
	if _voter_in_room != voter:
		return
	_voter_in_room = null
	next_voter_availability_updated.emit(is_next_voter_available())

#spawning voters signal handler
func _on_timer_timeout() -> void:
	if not _is_queue_consolidating and _any_free_queue_spots() and queued_voters.size() < _max_voter_queue:
		_spawn_voters()

	timer.start()       # Restart the X second timer
