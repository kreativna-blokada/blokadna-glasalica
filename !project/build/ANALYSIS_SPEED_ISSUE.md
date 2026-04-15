# Analysis: Voter Movement Speed and Inheritance Issues

## Overview
The `speed` parameter from the `Character` class **is** affecting the movement of the `Voter`, but several architectural factors in the current implementation make its behavior inconsistent or difficult to observe in the Godot Inspector.

## Key Findings

### 1. The "Double Move" Inheritance (Godot 4)
In Godot 4, both the parent (`Character`) and child (`Voter`) classes have their `_process` methods called if they are both implemented. 
*   **Character.gd**: `_process` calls `move_and_slide()`.
*   **Voter.gd**: `_process` also calls `move_and_slide()`.

Because of this, the physics engine processes the movement twice per frame, effectively doubling the intended velocity and potentially causing jitter or unexpected collisions.

### 2. Disconnected Inspector Defaults
The `Voter.tscn` scene file contains its own override for the `speed` property:
*   **Voter.tscn value**: `80.0`
*   **Character.gd default**: `0.0` (unset)

Changing the default value in the `Character.gd` script will not affect existing `Voter` instances because the scene's saved value takes precedence. To see an effect, the `speed` must be changed specifically on the `Voter` node/scene in the Inspector.

### 3. Unused Global Configuration
There is a speed definition in `config/configs.gd` (`Entity.Voter.speed = 200`), but this value is currently **orphaned**. Neither the `VotersFactory` nor the `Voter` script references this global configuration, relying instead on the local `speed` export.

## Code Evidence
In `voter.gd`, the velocity is explicitly set using the inherited `speed` variable:

```gdscript
# From voter.gd (voter_movement function)
velocity = movement_direction * speed
```

## Implementation Updates (Completed)
The following recommendations have been implemented:
1.  **Consolidated Movement**: `Voter.gd` now uses `super(_delta)` to defer to the base `Character.gd` logic, ensuring DRY code and preventing the "Double Move" bug.
2.  **Inspector Control (Verified)**: The `speed` value is now driven directly by the `Voter.tscn` Inspector settings. The global config override has been removed to allow fine-tuning in the Godot Editor.

## Understanding Polymorphism and Execution Flow

By refactoring the code to use `super(_delta)`, we have aligned the project with standard Godot/OOP practices (Polymorphism).

### How the Parent Calls Child Methods
In GDScript, all functions are **virtual** by default. This means that even when a method is called from inside a parent class (`Character.gd`), Godot always checks if the child class (`Voter.gd`) has an override for that specific method.

### Step-by-Step Execution Loop
When a `Voter` instance is processed, the flow works as follows:

1.  **Voter Instance**: Godot calls `Voter._process`.
2.  **Pre-Processing**: `Voter._process` runs custom velocity logic (`voter_movement`).
3.  **Parent Entry**: `Voter` calls `super(_delta)`, jumping into `Character._process`.
4.  **The "Call Back"**: Inside `Character.gd`, it hits `handle_movement()`.
5.  **Godot Routing**: Godot sees the object is a `Voter` and **jumps back** to `Voter.gd` to run its version of `handle_movement`.
6.  **Child Logic**: `Voter.handle_movement` runs (checking queue/stop states).
7.  **Explicit Parent Call**: `Voter` calls `super.handle_movement()` to finally run the basic idle/walk state switching in `Character.gd`.

### Visualizing the Loop
```text
[ Voter._process ]
    |--> Set velocity (voter_movement)
    |--> super(_delta) ----------------------> [ Character._process ]
                                                  |--> handle_input() (Runs Voter override)
                                                  |--> handle_movement() (Jumps back to Voter!)
                                                          |--> Custom Voter logic
                                                          |--> super() (Runs Character logic)
                                                  |--> handle_animations() (Jumps back to Voter!)
                                                  |--> set_heading() (Character version)
                                                  |--> move_and_slide() (Character version)
```

### Benefits of this Approach
*   **DRY (Don't Repeat Yourself)**: Core logic like `move_and_slide()` is defined once in the parent, reducing bugs across different character types.
*   **Safety**: Any global character features (e.g., a "Stunned" state) added to `Character.gd` will automatically apply to `Voter.gd` without extra effort.
*   **Correctness**: This eliminates the "Double Move" bug by ensuring `move_and_slide()` is only called once per frame.

## Detailed Inheritance & Method Execution Flow

### 1. `_process(_delta)`
Godot calls the "most specific" version of a callback. Since `Voter` extends `Character`:
*   Godot calls **`Voter._process(_delta)`**.
*   Inside `Voter._process`, the code uses `super(_delta)`, which explicitly calls **`Character._process(_delta)`**.

### 2. `handle_animations()` and others
Inside `Character._process`, the script calls `handle_animations()`. Because the object is a `Voter`, GDScript uses **polymorphism**:
*   `Character._process` calls **`Voter.handle_animations()`**.
*   Inside `Voter.handle_animations()`, if the logic hits the `else` block, it executes **`super.handle_animations()`**, which then runs the original code in **`Character.gd`**.

### Summary of the Flow:
1.  **Godot** → `Voter._process()`
2.  `Voter._process()` → `Character._process()` (via `super`)
3.  `Character._process()` → `Voter.handle_animations()` (via polymorphism)
4.  `Voter.handle_animations()` → `Character.handle_animations()` (via `super.handle_animations()`)

**Result:** Both classes execute their logic. Godot initiates the chain at the `Voter` level, and because `super` is used, the execution "bubbles up" to include the logic from `Character`. **If you removed `super.handle_animations()` from `Voter.gd`, the code in `Character.gd` would never run for a Voter.**

### Why `super(_delta)` vs `super.handle_animations()`?
*   **`super(_delta)`**: This is shorthand for `super._process(_delta)`. When you use `super` as a function, it calls the same-named function in the base class.
*   **`super.method_name()`**: This is the explicit way to call any specific method from the base class. Both achieve the same goal of ensuring the "parent" logic is executed alongside the child's overrides.

### Why it Doesn't Loop (The "Escape Hatch")
A common concern is whether `Voter.handle_animations()` → `Character.handle_animations()` (via `super`) will cause an infinite loop. **It will not**, because `super` is an explicit instruction to **bypass polymorphism**:

1.  **The "Virtual" Call (Normal Call)**: When `Character.gd` says `handle_animations()`, it is a **virtual call**. Godot looks at the object and says: *"This is a Voter, does it have an override?"* It finds the `Voter` version and jumps there.
2.  **The `super` Call (The "Escape Hatch")**: When `Voter.gd` says `super.handle_animations()`, it is **NOT** a virtual call. You are telling Godot: *"Go specifically to my parent (Character) and run **his** version of this function. Do not check for overrides."*
3.  **Completion**: Inside `Character.handle_animations()`, the code just plays an animation. There is no call back to `handle_animations()` within that function. Once those lines finish, the function ends, returns control to the `Voter` script, and the chain is complete.

**When WOULD it loop?**
An infinite loop would only happen if the Parent's function called *itself* again:
```gdscript
# CHARACTER.GD - THIS WOULD CAUSE A LOOP
func handle_animations() -> void:
    handle_animations() # Infinite recursion!
```

Because `super.handle_animations()` jumps directly to the parent's logic and stops looking for overrides, it is the safe way to "stack" child logic on top of parent logic without infinite recursion.

### The Case of `handle_input()`
In `Voter.gd`, you will notice `handle_input()` also uses `super.handle_input()`. The flow follows the same logic:

1.  **The "Virtual" Call**: `Character._process` calls `handle_input()`. Because it's a virtual call, Godot redirects this to **Voter.handle_input()**.
2.  **The `super` Call**: **Voter.handle_input()** then makes an explicit call back to the parent via `super.handle_input()`. As we established, this is **NOT** a virtual call; it tells Godot to run the parent's logic specifically.
3.  **Character.handle_input()** executes (currently just a `pass` statement).

**Why do this if the parent is empty?**
This is a "Future-Proofing" pattern. If you later decide that **all** characters should handle a specific input (like a "Debug Info" key or a "Pause" check), you only have to write it once in `Character.gd`. Because `Voter.gd` is already calling `super`, it will automatically inherit that new functionality without needing any code changes.
