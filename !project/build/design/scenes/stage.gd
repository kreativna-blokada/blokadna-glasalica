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
var _voters: Node = null
#var _voter_factory: PackedScene = preload("res://!project/build/design/scenes/actors/voters.tscn")

#broadcast variables
var _voter_diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

#onready vars
@onready var voter_slots: Node2D = $VoterSlots
@onready var voter_spots: Array = $VoterSpots.get_children()
@onready var voter_stops: Array = $VoterStops.get_children()
@onready var voter_stop: Node2D = $VoterStops/Load

@onready var _timer: Timer = $Timer

@onready var voting_stops: Array = $VoterStops.get_children()

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

	_voters = voter_slots
	_voter_diversity = Globals.VoterFactory.size()#+1
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

#handles the process of broadcasting entities
func _spawn_voters() -> void:
	var index: int = _rand.randi() % _voter_diversity
	
	_get_voter(index)

#handles the process of broadcasting entities
func _get_voter(_index: int) -> Node:
	if _voters and _voters.has_method("load_voter"):
		#var voter = _voters.select_voter(index)
		var voter = _voters.load_voter(_index)
		#dependency injection
		voter.stage = self

		var x: float = _rand.randf_range(600,3000)
		voter.position = Vector2(voter_stop.global_position.x, voter_stop.global_position.y)
		
		voter_slots.add_child(voter)
		
		print("[STAGE] Successfully fetched voter of index: ", _index)
		
		return voter
	else:
		push_error("Critical: _voters instance is null or missing script!")
		return null

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

#SIGNALS
#███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
#██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
#███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
#╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
#███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
#╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝

func _on_timer_timeout() -> void:
	#_increase_spawn_rate()
	_spawn_voters()
	_timer.start()       # Restart the X second timer
#Note: spawns enemies after initial time out expires
