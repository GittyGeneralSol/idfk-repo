extends Node2D

@onready var _known_worlds: Array = WorldUtils.get_worlds_by_void()
@onready var _all_world_positions: Dictionary = {}

signal _player_transported(_target_world: Node, _target_world_name: String)

func _ready() -> void:
    for world in _known_worlds:
        var world_name = world.world_name
        _all_world_positions[world_name] = world.global_position
    print("TRANSPORT MANAGER: ", _all_world_positions)
        
func transport_from_to(obj_to_transport: Node, target_world_name: String, target_pos: Vector2 = Vector2.ZERO):
    # --- 1. Acquire Worlds ---
    var target_world = await WorldUtils.request_world(target_world_name, self)
    if not is_instance_valid(target_world):
        printerr("TransportManager: Aborting, could not acquire target world '", target_world_name, "'")
        return
        
    var old_world = WorldUtils.get_parent_world(obj_to_transport)

    # --- 2. Handle Transport Logic ---
    if old_world == target_world:
        # If moving within the same world, just configure the object.
        _configure_transported_object(obj_to_transport, target_pos)
    else:
        # For inter-world travel, follow the full procedure.
        _handle_world_state_on_departure(old_world)
        
        var transported_obj = await _reparent_object(obj_to_transport, target_world)
        if not is_instance_valid(transported_obj):
            printerr("TransportManager: Aborting, object failed to reparent or be created.")
            return
        
        await _handle_world_state_on_arrival(target_world)
        _configure_transported_object(transported_obj, target_pos)
        _manage_old_world_lifecycle(old_world, target_world)
        _finalize_transport(target_world)


#=============================================================================
# PRIVATE HELPER MODULES
#=============================================================================

## Handles the physical act of moving the object between worlds.
## Creates a new player if the object being transported is invalid/dead.
func _reparent_object(obj: Node, target_world: Node) -> Node:
    var object_to_move = obj
    
    if not is_instance_valid(obj): # If somehow invalid, assume it's the player and try regetting
        obj = WorldUtils.get_player_node()
    
    # If the object is still invalid, assume it's the player and create a new one.
    if not is_instance_valid(obj):
        var PLAYER_SCENE = load("res://scenes/creatures/player.tscn")
        var new_player = PLAYER_SCENE.instantiate()
        target_world.add_child(new_player)
        object_to_move = new_player
    else:
        # Otherwise, just move the existing object.
        obj.reparent(target_world)
    
    # Wait for the next frame to ensure the parent is fully updated in the tree.
    await get_tree().process_frame
    return object_to_move

## Saves the state of the world being left.
func _handle_world_state_on_departure(old_world: Node):
    if not is_instance_valid(old_world): return
    
    var old_world_data: Dictionary = SaveManager._formulate_world_data(old_world)
    if old_world_data:
        SaveManager.save_world(old_world_data, old_world.world_name, Vars.save_slot_number)

## Loads the state of the world being entered.
func _handle_world_state_on_arrival(target_world: Node):
    pass # Handled by request_world

## Sets the final position and properties of the transported object.
func _configure_transported_object(obj: Node, target_pos: Vector2):
    if not is_instance_valid(obj): return
    
    obj._setting_up_vars = true # Use a flag to prevent unwanted logic in setters
    obj.scale = Vector2.ONE
    obj._worldly_position = target_pos
    obj._setting_up_vars = false

## Decides whether to remove the old world from the scene tree to save memory.
func _manage_old_world_lifecycle(old_world: Node, new_world: Node):
    if not is_instance_valid(old_world) or not is_instance_valid(new_world): return
    
    # Do not remove the old world if the new world has a reference to it (e.g., a PocketDimBox).
    var new_world_refs = _get_references_recursive(new_world, 2) # We want a 2-deep check.
    var reference_found = new_world_refs.has(old_world.world_name)
    if reference_found:
        return
        
    # Before deleting, register the old world's last known position.
    if not _all_world_positions.has(old_world.world_name):
        _all_world_positions[old_world.world_name] = old_world.global_position
    if not _known_worlds.has(old_world):
        _known_worlds.append(old_world)
        
    # Remove the world from the scene.
    var the_void = WorldUtils.get_void()
    if is_instance_valid(the_void):
        the_void._remove_world(old_world, self)

func _get_references_recursive(start_world: Node, depth: int) -> PackedStringArray:
    # Use a dictionary to automatically handle duplicates.
    var all_refs: Dictionary = {}
    _find_refs_internal(start_world, depth, all_refs)
    return all_refs.keys()


# The internal recursive part.
func _find_refs_internal(current_world: Node, remaining_depth: int, found_refs: Dictionary):
    # --- Base Cases to stop the recursion ---
    
    # 1. We've reached the maximum depth.
    if remaining_depth <= 0:
        return
        
    # 2. The current world isn't valid/loaded.
    if not is_instance_valid(current_world):
        return

    # --- Recursive Step ---
    
    # Get the direct references of the current world.
    var direct_refs = current_world.world_refs
    
    for ref_name in direct_refs:
        # Add the found reference to our master list.
        found_refs[ref_name] = true
        
        # Now, try to go one level deeper from this new reference.
        var next_world = WorldUtils.get_world_by_void(ref_name)
        _find_refs_internal(next_world, remaining_depth - 1, found_refs)
    
## Finalizes the process with any last-step save actions or UI resets.
func _finalize_transport(_target_world: Node):
    SaveManager._form_and_save_player_data()
    Vars.set_mobile_tap_move(true) # Reset buttons or mobiletapmove will freeze
    emit_signal("_player_transported", _target_world, _target_world.world_name)
