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

#private vars
#data containers
var _voters: Node = null
var _voter_factory: PackedScene = preload("res://!project/build/design/scenes/actors/voters.tscn")

#broadcast variables
var _diversity: int = 0
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

#onready vars
@onready var voter_slots: Node2D = $VoterSlots
@onready var voter_spots : Array = $VoterSpots.get_children()
@onready var voter_stops : Array = $VoterStops.get_children()

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

	_voters = _voter_factory.instantiate()
	_diversity = _voters.get_child_count()+1
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

#handles the process of broadcasting entities
func _spawn_voters() -> void:
	var index = _rand.randi() % _diversity
	
	if _voters and _voters.has_method("load_voter"):
		#var voter = _voters.select_voter(index)
		var voter = _voters.load_voter(index)

		var x = _rand.randf_range(600,3000)
		voter.position = Vector2(690.0, 1040.0)

		add_child(voter)
		
		print("Voter spawned successfully at index: ", index)
	else:
		push_error("Critical: _voters instance is null or missing script!")

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
