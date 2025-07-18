@tool

extends Node

var WU_DEBUG_PREFIX = "WorldUtils - "
var _worlds_pending_creation: Array[String] = [] # Worlds not created just yet
@export var current_player_world: Node
@export var counter: int = 1
const DEFAULT_WORLD = preload("res://scenes/worlds/world_default.tscn")

## Signals:
signal world_created(world_name, world_node, caller)
signal world_deleted(world_name, world_node, caller)

## Line-of-sight:
func is_block_in_way(caller: Node, angle_to_target: float, length_to_check: float = 1000.0, angle_type: String = "degrees") -> bool:
    var tile_map = get_parent_world_tile_map(caller)
    var caller_pos = round(caller._worldly_position / Constants.tile_size)
    var block_in_way: bool = false
    var angle = deg_to_rad(angle_to_target) if angle_type == "degrees" else angle_to_target
    var check_pos: Vector2
    var R_in_terms_of_blocks = round(length_to_check / Constants.tile_size)
    
    for block_num in R_in_terms_of_blocks - 1:
        var r_in_pixels = block_num * Constants.tile_size + Constants.tile_size
        var pos_in_p: Vector2 = Vector2(r_in_pixels * cos(angle), r_in_pixels * sin(angle))
        var pos_in_grid: Vector2 = round(pos_in_p / Constants.tile_size) # Relative
        check_pos = pos_in_grid + caller_pos # Absolute
        
        if !tile_map.has(check_pos):
            continue # Skip this grid_pos if it doesnt exist
        
        if tile_map[check_pos] is Block:
            block_in_way = true
            break # Break the loop if a block is found in the way
            
    return block_in_way

## Private Helper
func _apply_worldly_position_to_node_transform(obj: Node, new_worldly_position: Vector2):
    if not is_instance_valid(obj):
        printerr("WorldUtils: Cannot apply worldly position to invalid object.")
        return

    var parent_world = get_parent_world(obj)

    if parent_world != null:
        var new_absolute_global_position = parent_world.to_global(new_worldly_position)
        obj.global_position = new_absolute_global_position
    else:
        printerr("WorldUtils: No parent World found for " + obj.name + ". Setting global_position directly as fallback.")
        obj.global_position = new_worldly_position # Fallback if no World found

## External scripts shall call THIS:
func set_worldly_position(obj: Node, new_worldly_position: Vector2):
    if obj.has_method("set_worldly_position"): # Check if it has a custom setter
        # If the node has a custom setter, call it.
        obj.set_worldly_position(new_worldly_position) # Call the specific setter method
    else:
        # If the node doesn't have a custom setter, apply it directly using the helper.
        _apply_worldly_position_to_node_transform(obj, new_worldly_position)

func get_worldly_position(obj: Node) -> Vector2:
    if not is_instance_valid(obj):
        printerr("WorldUtils: Cannot get worldly position for invalid object.")
        return Vector2.ZERO
    var parent_world = get_parent_world(obj)
    if parent_world != null:
        return parent_world.to_local(obj.global_position)
    else:
        printerr("WorldUtils: No parent World found for node: " + obj.name + ". Returning global_position instead.")
        return obj.global_position
        
func convert_global_to_local_pos(a_global_position: Vector2, stabilizing_obj: Node) -> Vector2:
    if not stabilizing_obj:
        return Vector2.ZERO
        
    var local_position = stabilizing_obj.to_local(a_global_position)
    return local_position
    
func obj_is_inside_its_world(obj: Node) -> bool:
    if not obj:
        return false
    
    var obj_world = WorldUtils.get_parent_world(obj)
    
    if not obj_world:
        return false
    
    var pos_obj = obj._worldly_position
    var pos_grid = roundi(pos_obj / Constants.tile_size)
    
    return pos_is_inside_rect(pos_grid, obj_world.world_size)
    
func pos_is_inside_rect(check_pos: Vector2i, grid_size: Vector2i) -> bool:
    var x = grid_size.x/2
    var y = grid_size.y/2
    
    if abs(check_pos.x) > x:
        return false
    
    if abs(check_pos.y) > y:
        return false
        
    return true

func get_parent_any_type(obj: Node, class_nam: String) -> Node:
    if not is_instance_valid(obj) or not obj.get_parent():
        return null

    var current_node: Node = obj.get_parent()

    while current_node != null:
        if current_node.is_class(class_nam):
            return current_node
        
        current_node = current_node.get_parent()
        
    return null
    
func get_gui_node() -> Node:
    var the_void: Node
    
    if get_void():
        the_void = get_void()
    else: return null
    
    if the_void.has_node("GUI"):
        return the_void.get_node("GUI")
    else: return null

func get_player_node(obj: Node = null) -> Node:
    if obj: # If a reference node is given.. use it. This method unfortunately needs a parent world to work. No parent world, no player found.
        if not get_parent_world(obj):
            return null
        if not (WorldUtils.get_parent_world(obj).has_node("Player")): # This method also has limited range: can only search the caller's world for player.
            return null
        return WorldUtils.get_parent_world(obj).get_node("Player")
    else: # Search the entire tree for player. Does not need reference node.
        var player = get_tree().root.find_child("Player", true, false)
        
        if player:
            return player
        else: return null
  
func get_parent_creature(obj: Node) -> Node:
    if not is_instance_valid(obj) or not obj.get_parent():
        return null

    var current_node: Node = obj.get_parent()

    while current_node != null:
        if current_node is BaseCreature:
            return current_node
        
        current_node = current_node.get_parent()
        
    return null
  
func get_parent_block(obj: Node) -> Node:
    if not is_instance_valid(obj) or not obj.get_parent():
        return null

    var current_node: Node = obj.get_parent()

    while current_node != null:
        if current_node is Block:
            return current_node as Block
        
        current_node = current_node.get_parent()
        
    return null

func get_void() -> Node:
    var the_void = get_tree().root.find_child("Void", true, false)
        
    if the_void:
        return the_void
    else: return null

## CRITICAL Call THIS function instead of instantiate_and_get_world.
func request_world(world_name: String, caller: Node) -> Node:
    # Check 1: World already exists and is ready.
    var existing_world = get_world_by_void(world_name)
    if is_instance_valid(existing_world):
        return existing_world

    # Check 2: World is currently being created by another caller. Wait for it.
    if world_name in _worlds_pending_creation:
        var created_world = await _wait_for_specific_world(world_name)
        return created_world

    # If we reach here, we are the designated creator.

    # Set the lock so others will wait.
    _worlds_pending_creation.append(world_name)
    
    # Wait one frame so other scripts in the same frame can see the lock.
    await get_tree().process_frame
    
    # Instantiate and add the world to the scene tree.
    var world_instance = _instantiate_scene_for_world(world_name)
    if not is_instance_valid(world_instance):
        printerr("WorldUtils: Failed to instantiate scene for '", world_name, "'")
        _worlds_pending_creation.erase(world_name) # Release lock on failure
        return null
        
    get_void().add_child(world_instance)
    
    # THE CRUCIAL WAIT: Await one more frame AFTER adding to the tree.
    # This guarantees its global_position is calculated and valid.
    await get_tree().process_frame
    
    # 1. Handle the file and AWAIT its completion.
    await handle_world_file(world_instance, world_name)
    
    # 2. The world is now TRULY "baked" and ready. Announce its creation.
    world_created.emit(world_name, world_instance, caller)
    
    # 3. Release the lock.
    _worlds_pending_creation.erase(world_name)
    
    # 4. Return the fully ready-to-use world.
    return world_instance

# --- Private Helper Functions ---

func _wait_for_specific_world(world_name: String):
    while true:
        var signal_args = await world_created
        if signal_args[0] == world_name:
            return signal_args[1] # Return the world_node

func _instantiate_scene_for_world(world_name: String) -> World:
    var world_scene_path = "res://scenes/worlds/" + world_name + ".tscn"
    var world_scene = load(world_scene_path)
    if not world_scene:
        print("WorldUtils: Could not load scene at path: ", world_scene_path, ". Attempting to create from default instead.")
        var world_instance = _create_world_from_default(world_name)
        
        if world_instance:
            return world_instance
        else:
            return null
    
    var world_instance = world_scene.instantiate()
    world_instance.world_name = world_name 
    return world_instance
    
func _create_world_from_default(world_name: String) -> World:
    if not is_instance_valid(DEFAULT_WORLD):
        printerr("WorldUtils: Could not load DEFAULT_WORLD scene.")
        return null
        
    var world_instance = DEFAULT_WORLD.instantiate()
    world_instance.world_name = world_name
    return world_instance
    
func handle_world_file(world_instance: World, world_name: String) -> bool:
    # First validity check
    if not is_instance_valid(world_instance):
        return false
        
    ## Load the file for the world, if existent, and then apply it's data:
    var player_node = WorldUtils.get_player_node()
    
    if not player_node:
        return false
        
    # Do not load file if world is literally just player_world
    if (world_instance != WorldUtils.get_parent_world(player_node)):
        var world_data = SaveManager.load_world(world_name, Vars.save_slot_number)
        SaveManager.apply_world_data(world_data, world_instance)
        
        return true
    else:
        return false
    

# --- End Helpers ---   
    
func get_world_by_name(world_name: String) -> Node:
    var world_to_find: Node
    
    for world in get_tree().get_nodes_in_group("worlds"):
        if world.world_name == world_name:
            world_to_find = world
            break
    if world_to_find:
        return world_to_find
    else:
        return null
        
func get_worlds_by_void() -> Array:
    var void_children = WorldUtils.get_void().get_children()
    var worlds: Array
    for void_child in void_children:
        if void_child is not World:
            continue
            
        var world = void_child
        worlds.append(world)
    return worlds
        
func get_world_by_void(world_name: String) -> Node:
    var worlds_found_with_name: Array
    var void_children = WorldUtils.get_void().get_children()
    
    for void_child in void_children:
        if void_child is not World:
            continue
            
        var world = void_child
        
        if world.world_name == world_name:
            worlds_found_with_name.append(world)
    
    if worlds_found_with_name.is_empty():
        return null
    
    if worlds_found_with_name.size() == 1:
        return worlds_found_with_name[0]
    elif worlds_found_with_name.size() > 1:
        printerr(WU_DEBUG_PREFIX + "get_world_by_void - THE NUMBER OF WORLDS FOUND FOR WORLD_NAME '", world_name,"' EXCEEDS ONE.")
        return null
    else: # Negative worlds found??
        printerr(WU_DEBUG_PREFIX + "get_world_by_void - THE NUMBER OF WORLDS FOUND FOR WORLD_NAME '", world_name,"' IS NONSENSICAL.")
        return null
        
func does_void_have_world_name(world_name: String) -> bool:
    var world_found: bool
    
    var void_children = WorldUtils.get_void().get_children()
    
    for void_child in void_children:
        if void_child is not World:
            continue
            
        var world = void_child
        
        if world.world_name == world_name:
            world_found == true
            break
    
    if world_found:
        return true
    else:
        return false

func get_parent_world(obj: Node) -> Node:
    if not is_instance_valid(obj) or not obj.get_parent():
        return null

    var current_node: Node = obj.get_parent() # Start checking from the immediate parent

    # Loop upwards through the hierarchy as long as there's a parent node
    while current_node != null:
        # If the current node is an instance of 'World', we found it.
        if current_node is World:
            return current_node as World # Return the found World node, cast to its type
        
        # If not a World, move up to its parent.
        current_node = current_node.get_parent()
        
    # If the loop finishes (meaning we reached the root of the tree without finding a World), return null.
    return null
    
func get_parent_world_tile_map(obj: Node) -> Dictionary:
    if get_parent_world(obj) and get_parent_world(obj).current_tile_map: return get_parent_world(obj).current_tile_map
    else: return {}
    
func get_parent_world_astar_grid(obj: Node) -> AStarGrid2D:
    if not get_parent_world(obj):
        return
    
    return get_parent_world(obj).astar_grid
    
func update_astar_grid(obj: Node):
    if not (get_parent_world(obj) and get_parent_world(obj).current_tile_map):
        return
    
    get_parent_world(obj).update_astar_grid()
    

func is_in_player_world(obj: Node) -> bool:
    # Check to see if the given object's world contains the player or not.
    if get_parent_world(obj) and get_parent_world(obj).has_node("Player"): return true
    else: return false
    
func get_current_player_world() -> Node:
    return current_player_world

func set_current_player_world(obj: Node) -> void:
    current_player_world = get_parent_world(obj)
