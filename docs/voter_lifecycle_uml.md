# Voter Lifetime UML

This document summarizes the lifetime of a voter actor as implemented in the Godot source. The diagrams focus on creation, active lifecycle, queue/stop interaction, and disposal.

Primary source files:

- `!project/build/design/scenes/actors/voter.gd`
- `!project/build/design/scenes/actors/voters.gd`
- `!project/build/design/scenes/stage.gd`
- `!project/build/design/scenes/scenery/voting_stop.gd`
- `!project/build/design/scenes/actors/character.gd`

## Class UML

```mermaid
classDiagram
    direction LR

    class CharacterBody2D {
        <<Godot>>
    }

    class Node2D {
        <<Godot>>
    }

    class Node {
        <<Godot>>
    }

    class Character {
        <<abstract-ish base>>
        +float movement_speed
        -State _state
        +_process(delta) void
        +handle_input() void
        +handle_movement() void
        +handle_animations() void
        +can_move() bool
    }

    class Voter {
        +signal voter_queued
        +signal voter_stopped(vote_stop_name: String)
        +int voter_factory_index
        +VotingStop starting_spot
        +int voting_course_pointer
        +Array voting_course
        +bool is_queueing
        +bool is_stopping
        -Texture2D _cached_texture
        -Dictionary _wait_frame_coord
        -String _walk_animation_name
        -bool _state_entered
        -bool _is_shuffling
        -bool _is_course_finished
        -Node2D _course_target
        +_ready() void
        +_process(delta) void
        +set_walking_course(stops: Array) void
        +voter_movement() void
        +can_leave_queue() bool
        +can_continue_voting_course() bool
        +assign_queue_spot(target_queue_spot: Node2D) void
        +play_stop_sound() void
        -_on_stop_reach() void
        -_on_queue_reached() void
        -_on_stop_reached() void
        -_next_stop() void
        -_update_course_target() void
        -_free_current_stop() void
        -_voter_occupies_stop(pointer: int) void
    }

    class VotersFactory {
        -PackedScene _voter_scene
        -String _voter_group
        -Dictionary _voter_scene_struct
        +load_voter(index: int) Node
        -_get_texture(index: int) Resource
    }

    class Stage {
        +signal queue_count_updated(count: int)
        +signal stops_occupancy_updated(stops_occupancy_flags: Array)
        +Array queued_voters
        -Voter _selected_voter
        -int _max_voter_queue
        -int _voters_diversity
        -RandomNumberGenerator _rand
        -String _pending_vote_stop_name
        +_ready() void
        +get_voting_course(voter: Voter) Array
        -_spawn_voters() void
        -_get_voter(index: int) Voter
        -_dequeue_voter(voter: Voter) void
        -_shift_voters_forward() void
        -_select_next_voter() void
        -_on_voter_queued(voter: Voter) void
        -_on_voter_stopped(vote_stop_name: String) void
        -_on_timer_timeout() void
    }

    class VotingStop {
        +signal occupancy_updated
        +Character occupant
        +bool is_stop
        +AudioStream stop_sound
        +AudioStream cool_sound
        +float sound_volume
        +StopAnim walk_animation
        +StopAnim wait_animation
        +is_free() bool
        +free_up() void
        +occupy(character: Character) void
        +get_wait_animation_name() String
        +get_walk_animation_name() String
    }

    CharacterBody2D <|-- Character
    Character <|-- Voter
    Node <|-- VotersFactory
    Node2D <|-- Stage
    Node2D <|-- VotingStop

    Stage "1" o-- "many" Voter : owns as VoterSlots children
    Stage "1" --> "1" VotersFactory : calls load_voter()
    Stage "1" --> "many" VotingStop : queue_spots/voting_course
    Voter "1" --> "many" VotingStop : voting_course
    VotingStop "0..1" --> "1" Character : occupant
    VotersFactory ..> Voter : instantiates voter.tscn
```

## Creation / Instantiation Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Timer as Timer / Stage._ready()
    participant Stage
    participant Factory as VotersFactory
    participant Scene as voter.tscn PackedScene
    participant Voter
    participant QueueSpot as VotingStop(queue spot)
    participant Stop as VotingStop(course stop)

    alt initial game setup
        Timer->>Stage: _ready()
        Stage->>Stage: _init_vars()
        Stage->>Stage: _init_nodes()
        Stage->>Stage: _init_signals()
        Stage->>Stage: _get_voter(0)
    else periodic spawn
        Timer->>Stage: _on_timer_timeout()
        Stage->>Stage: _any_free_queue_spots()
        Stage->>Stage: _spawn_voters()
        Stage->>Stage: _get_voter(random_index)
    end

    Stage->>Factory: load_voter(index)
    Factory->>Scene: instantiate()
    Scene-->>Factory: Voter node
    Factory->>Voter: voter_factory_index = index
    Factory->>Voter: add_to_group("voter")
    Factory->>Voter: set CharacterSprite texture
    Factory-->>Stage: voter

    Stage->>Stage: add_child(voter)
    Note over Stage,Voter: Godot calls Voter._ready() after the node enters the scene tree.
    Voter->>Voter: duplicate CharacterSprite material

    Stage->>Voter: position = Load.global_position
    Stage->>Stage: get_voting_course(voter)
    Stage->>QueueSpot: occupy(voter)
    QueueSpot-->>Stage: occupancy_updated
    Stage->>Voter: set_walking_course([Load, queue spot, stops...])
    Voter->>Voter: _update_course_target()
    Voter->>Stop: get_walk_animation_name()
    Stage->>Voter: connect voter_queued -> _on_voter_queued(voter)
    Stage->>Voter: connect voter_stopped -> _on_voter_stopped(name)
```

## Interaction Sequence: Queue, Stops, and Disposal

```mermaid
sequenceDiagram
    autonumber
    participant GameLoop as Godot frame loop
    participant Stage
    participant Voter
    participant QueueSpot as VotingStop(queue spot)
    participant Stop as VotingStop(course stop)
    participant Info as InfoDialog

    loop each process frame while active
        GameLoop->>Voter: _process(delta)
        alt queueing, stopping, finished, or no target
            Voter->>Voter: velocity = Vector2.ZERO
        else walking toward _course_target
            Voter->>Voter: voter_movement()
            Voter->>Voter: _on_stop_reach() when close enough
        end
        Voter->>Voter: Character._process(delta)
        Voter->>Voter: handle_movement()
        Voter->>Voter: handle_animations()
        Voter->>Voter: move_and_slide()
    end

    Voter->>Voter: reach Load at pointer 0
    Voter->>Voter: _next_stop()
    Voter->>Voter: _update_course_target(queue spot)

    Voter->>Voter: reach queue spot at pointer 1
    Voter->>Voter: _on_queue_reached()
    alt shuffling within queue
        Voter->>Voter: _is_shuffling = false
    else first queue arrival
        Voter->>Voter: is_queueing = true
        Voter->>Voter: starting_spot = queue spot
        Voter-->>Stage: voter_queued
        Stage->>Stage: queued_voters.append(voter)
        Stage-->>Stage: queue_count_updated(size)
    end

    Stage->>Voter: can_leave_queue()
    Voter->>Voter: _is_next_stop_free()
    Voter->>Stop: is_free()
    alt next stop is occupied
        Voter-->>Stage: false
    else next stop is free
        Voter->>Stop: occupy(voter)
        Stop-->>Stage: occupancy_updated
        Voter->>Voter: is_queueing = false
        Voter->>Voter: _next_stop()
        Voter-->>Stage: true
        Stage->>Stage: queued_voters.erase(voter)
        Stage->>QueueSpot: free_up()
        QueueSpot-->>Stage: occupancy_updated
        Stage->>Stage: _shift_voters_forward()
    end

    loop each voting course stop
        Voter->>Voter: reach course target
        Voter->>Voter: _on_stop_reached()
        Voter->>Stop: occupy(voter)
        Stop-->>Stage: occupancy_updated
        alt stop.is_stop == true
            Voter->>Voter: is_stopping = true
            Voter-->>Stage: voter_stopped(stop.name)
            Stage->>Stage: _pending_vote_stop_name = stop.name
            opt player opens info
                Stage->>Info: show_info(stop.name)
                Info-->>Stage: dialog_closed
            end
            Stage->>Voter: can_continue_voting_course()
            Voter->>Voter: _is_next_stop_free()
            Voter->>Stop: free_up()
            Stop-->>Stage: occupancy_updated
            Voter->>Voter: is_stopping = false
            Voter->>Voter: _next_stop()
        else transitional stop
            Voter->>Stop: free_up()
            Stop-->>Stage: occupancy_updated
            Voter->>Voter: _next_stop()
        end
    end

    Voter->>Voter: _update_course_target()
    alt voting_course_pointer is past final stop
        Voter->>Voter: _course_target = null
        Voter->>Voter: _is_course_finished = true
        Voter->>Voter: velocity = Vector2.ZERO
        Voter->>Voter: queue_free()
        Note over Voter: Godot queues the node for deletion at the end of the frame.
    end
```

## State / Lifetime UML

```mermaid
stateDiagram-v2
    [*] --> Instantiated: VotersFactory.load_voter()
    Instantiated --> InSceneTree: Stage.add_child(voter)
    InSceneTree --> Initialized: Voter._ready()
    Initialized --> WalkingToQueue: set_walking_course()

    WalkingToQueue --> Queueing: reaches voting_course[1]\n_on_queue_reached()
    Queueing --> WalkingToFirstStop: Stage._dequeue_voter()\ncan_leave_queue()
    Queueing --> ShufflingForward: Stage._shift_voters_forward()\nassign_queue_spot()
    ShufflingForward --> Queueing: reaches new queue spot

    WalkingToFirstStop --> StoppingAtActionStop: reaches stop where is_stop == true
    WalkingToFirstStop --> TransitionalStop: reaches stop where is_stop == false
    TransitionalStop --> WalkingToNextStop: free current stop\n_next_stop()

    WalkingToNextStop --> StoppingAtActionStop: reaches stop where is_stop == true
    WalkingToNextStop --> TransitionalStop: reaches stop where is_stop == false

    StoppingAtActionStop --> WaitingForRelease: voter_stopped signal emitted
    WaitingForRelease --> WalkingToNextStop: can_continue_voting_course()

    WalkingToNextStop --> Finished: no next VotingStop
    TransitionalStop --> Finished: no next VotingStop
    Finished --> Disposed: queue_free()
    Disposed --> [*]
```

## Lifecycle Notes

- Voters are not constructed with `Voter.new()` in the game flow. They are instantiated from `voter.tscn` by `VotersFactory.load_voter()`.
- `Stage._get_voter()` owns the setup after instantiation: it adds the voter to `VoterSlots`, positions it at `Load`, builds its `voting_course`, connects signals, and starts movement by calling `set_walking_course()`.
- Queue positions and course stops are both represented by `VotingStop` nodes. They track occupancy through `occupy()` and `free_up()`, then emit `occupancy_updated`.
- The voter controls its own path progression with `voting_course_pointer` and `_course_target`.
- User input does not move a voter directly. `Stage` selects a queued/stopped voter, then calls either `can_leave_queue()` or `can_continue_voting_course()`.
- Disposal is internal to `Voter._update_course_target()`: when `voting_course_pointer` moves beyond the available course, `_is_course_finished` is set and `queue_free()` schedules the node for deletion.
