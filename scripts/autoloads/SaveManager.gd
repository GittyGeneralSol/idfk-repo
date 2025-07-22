@tool
extends Node

const SAVES_DIRECTORY = "user://saves/"
const PERSISTANT_DIRECTORY = "user://persistant/"

# --- Loaded Scenes ---
# Reuse already loaded scenes, no need to reload
var _loaded_scenes: Dictionary = {}

## -- Superb Utility --
func load_and_instance(scene_name: String, scene_path: String) -> Node:
    var scene: PackedScene

    # Get the PackedScene
    if _loaded_scenes.has(scene_name):
        scene = _loaded_scenes[scene_name]
    else:
        scene = load(scene_path)
        if scene != null:
            _loaded_scenes[scene_name] = scene # 'scene_name' is the key to access this scene later on

    # Handle failure
    if not is_instance_valid(scene):
        printerr("SAVEMANAGER ERROR: FAILED to load PackedScene with path '", scene_path, "'. Given scene_name: ", scene_name)
        return null

    # Instantiate and return
    var instance = scene.instantiate()
    
    if not is_instance_valid(instance):
        printerr("SAVEMANAGER ERROR: FAILED to instantiate scene with path '", scene_path, "'. Given scene_name: ", scene_name)
        return null

    return instance
    
# Formats a dictionary for saving
func format_dictionary(dict: Dictionary) -> Dictionary:
    var formatted_dict: Dictionary
    for property_name in dict.keys():
        var value = dict[property_name]
        value = format_variable(value)
        formatted_dict[property_name] = value
    return formatted_dict
    
func format_array(arr: Array) -> Array:
    var formatted_arr: Array
    formatted_arr.resize(arr.size())
    for i in range(arr.size()):
        var value = arr[i]
        value = format_variable(value)
        formatted_arr[i] = value
    return formatted_arr
    
func format_variable(value: Variant) -> Variant:
    var formatted_val: Variant
    # PERFORM Operations ON DATA BY TYPE
    if value is Dictionary:
        formatted_val = format_dictionary(value)
    elif value is int:
        formatted_val = value
    elif value is float:
        formatted_val = value
    elif value is Vector2:
        formatted_val = {"x": value.x, "y": value.y }
    elif value is Vector3:
        formatted_val = {"x": value.x, "y": value.y, "z": value.z }
    elif value is Vector4:
        formatted_val = {"x": value.x, "y": value.y, "z": value.z, "w": value.w }
    elif value is Color:
        formatted_val = {"r": value.r, "g": value.g, "b": value.b, "a": value.a }
    elif value is String:
        formatted_val = value
    elif value is Array:
        formatted_val = format_array(value)
    else:
        formatted_val = var_to_str(value)
    return formatted_val

## -- General --

func _form_and_save_player_data(slot_number: int = Vars.save_slot_number) -> bool:
    var player_data = _formulate_player_data()
    if player_data:
        save_player(player_data, slot_number)
        return true
    return false
    
func _load_and_apply_player_data(slot_number: int = Vars.save_slot_number) -> bool:
    var player_data = load_player(slot_number)
    if player_data:
        await apply_player_data(player_data)
        return true
    return false
    
func _load_and_apply_world_data(world_name: String, slot_number: int = Vars.save_slot_number) -> bool:
    var world_data = load_world(world_name, slot_number)
    
    var world = WorldUtils.get_world_by_void(world_name)
    
    if not world or not is_instance_valid(world):
        printerr("SaveManager - (_load_and_apply_world_data) - Unable to retrieve world with name '", world_name)
        return false
    
    if world_data:
        apply_world_data(world_data, world)
        return true
    return false
    
func _form_and_save_symbol(symbol_points: PackedVector2Array, symbol_name: String, desc: String = "Standard custom symbol. Useful for re-using the same shapes over and over."):
    var symbol_data = SaveManager._formulate_symbol_data(symbol_points, desc)
    SaveManager.save_symbol(symbol_data, symbol_name)


## -- Getting File and Directory Paths --

func _get_save_path(slot_number: int = Vars.save_slot_number) -> String:
    if not DirAccess.dir_exists_absolute(SAVES_DIRECTORY):
        var error_code = DirAccess.make_dir_recursive_absolute(SAVES_DIRECTORY) 
        if error_code != OK:
            printerr("Failed to create SAVES directory: ", SAVES_DIRECTORY, " - Error code: ", error_code)
            return ""
    
    var save_slot_directory = SAVES_DIRECTORY + "save_" + str(slot_number)
    
    if not DirAccess.dir_exists_absolute(save_slot_directory):
        var error_code = DirAccess.make_dir_recursive_absolute(save_slot_directory) 
        if error_code != OK:
            printerr("Failed to create save slot directory: ", save_slot_directory, " - Error code: ", error_code)
            return ""
    
    return save_slot_directory + "/game_save.json" # Append main save file name here

func _get_world_path(world_name: String, save_slot_number: int = Vars.save_slot_number) -> String:
    var save_slot_directory = _get_save_path(save_slot_number).get_base_dir() # Get the directory part
    if save_slot_directory.is_empty():
        return ""

    var worlds_directory = save_slot_directory + "/worlds/"
    if not DirAccess.dir_exists_absolute(worlds_directory):
        var error_code = DirAccess.make_dir_recursive_absolute(worlds_directory) 
        if error_code != OK:
            printerr("Failed to create worlds directory: ", worlds_directory, " - Error code: ", error_code)
            return ""
    
    # FIX: Return the actual file path, not just the directory
    var world_file_path = worlds_directory + world_name + ".json"
    return world_file_path
    
func _get_player_path(save_slot_number: int = Vars.save_slot_number) -> String:
    var save_slot_directory = _get_save_path(save_slot_number).get_base_dir() # Get the directory part
    if save_slot_directory.is_empty():
        return ""
    
    # FIX: Return the actual file path, not just the directory
    var player_file_path = save_slot_directory + "/player" + ".json"
    return player_file_path

func _get_creature_path(creature_name: String = "unnamed" + str(rand_from_seed(randi()))) -> String:
    var custom_creatures_dir = PERSISTANT_DIRECTORY + "/custom_creatures/"
    var creature_path = custom_creatures_dir + creature_name + ".json"
    
    if not DirAccess.dir_exists_absolute(custom_creatures_dir):
        var error_code = DirAccess.make_dir_recursive_absolute(custom_creatures_dir) 
        if error_code != OK:
            printerr("Failed to create custom_creatures directory: ", custom_creatures_dir, " - FOR: " + creature_path + " - Error code: ", error_code)
            return ""
            
    return creature_path
    
func _get_symbol_path(symbol_name: String = "unnamed" + str(rand_from_seed(randi()))) -> String:
    var custom_symbols_dir = PERSISTANT_DIRECTORY + "/custom_symbols/"
    var symbol_path = custom_symbols_dir + symbol_name + ".json"
    
    if not DirAccess.dir_exists_absolute(custom_symbols_dir):
        var error_code = DirAccess.make_dir_recursive_absolute(custom_symbols_dir) 
        if error_code != OK:
            printerr("Failed to create custom_symbols directory: ", custom_symbols_dir, " - FOR: " + symbol_path + " - Error code: ", error_code)
            return ""
            
    return symbol_path
    
## -- Formulation of Data --

func _formulate_player_data() -> Dictionary:
    var player = WorldUtils.get_player_node()
    var parent_world = WorldUtils.get_parent_world(player)
    var player_pos = player._worldly_position
    var player_data: Dictionary
    player_data = {
            "class": "BaseCreature",
            "parent_world": parent_world.world_name,
            "creature_name": "unnamed",
            "max_hp": player.max_hp,
            "hp": player.hp,
            "creature_position": { "x": player_pos.x, "y": player_pos.y },
        }
    print("ASKS - player_pos: ", player._worldly_position)
    return player_data

func _formulate_world_data(world: Node) -> Dictionary:
    var world_name = world.world_name
    var world_size = world.world_size
    
    var current_world_state: Dictionary = {}
    
    ## General world info:
    var bg_color: Color = world.bg_color
    var world_info = {
        "world_size": { "x": world_size.x, "y":  world_size.y },
        "bg_color": { "r": bg_color.r, "g": bg_color.g, "b": bg_color.b, "a": bg_color.a }
    }
    current_world_state["world_info"] = world_info
    
    ## Creatures:
    var creature_counter = 1
    var creature_list = get_creature_list(world)
    for creature in creature_list:
        var parent_world = WorldUtils.get_parent_world(creature)
        var creature_data = {
            "class": "BaseCreature",
            "creature_name": "unnamed",
            "creature_type": creature.creature_type,
            "max_hp": creature.max_hp,
            "hp": creature.hp,
            "parent_world": parent_world.world_name,
            "creature_position": { "x": creature._worldly_position.x, "y": creature._worldly_position.y },
        }
        current_world_state["creature_" + str(creature_counter)] = creature_data
        creature_counter += 1
        
    ## Blocks:
    var block_counter = 1
    var block_list = get_block_list(world)
    for block in block_list:
        var parent_world = WorldUtils.get_parent_world(block)
        var block_data = {
            "class": "Block",
            "block_name": "unnamed",
            "block_type": block.block_type,
            "parent_world": parent_world.world_name,
            "block_position": { "x": block._worldly_position.x, "y": block._worldly_position.y },
        }
        if block.has_method("get_special_data"): block_data[block.get_special_data("title")] = block.get_special_data()
        current_world_state["block_" + str(block_counter)] = block_data
        block_counter += 1
    
    return current_world_state
    
func _formulate_creature_data(creature: BaseCreature, desc: String = "Standard custom creature.") -> Dictionary:
    if Engine.is_editor_hint() or !self.is_node_ready():
        return {}
    
    var creature_data: Dictionary = {
        "description": desc,
        "logic": {},
        "parts": {}
    }
    
    ## Logic
    var logic_data: Dictionary = format_dictionary(creature.get_logic_data())
    creature_data["logic"] = logic_data
    
    ## Parts
    var parts_data: Dictionary
    var parts = creature.get_child_parts()
    
    for part: BaseCreaturePart in parts:
        parts_data[part.name] = part.part_properties
    
    creature_data["parts"] = parts_data
    return creature_data
    
func _formulate_symbol_data(symbol_points: PackedVector2Array, desc: String = "Standard custom symbol. Useful for re-using the same shapes over and over.") -> Dictionary:
    if !self.is_node_ready():
        return {}
    
    var symbol_data: Dictionary
    
    symbol_data["description"] = desc
    symbol_data["symbol_points"] = var_to_str(symbol_points)
    return symbol_data
    
func get_creature_list(world: Node, indiscriminate: bool = false) -> Array:
    var creature_list: Array
    var world_children = world.get_children()
    for child in world_children:
        if not indiscriminate:
            # Check if basecreature
            if child is BaseCreature:
                if child.creature_type == "player" or child.is_frozen or child.dead:
                    continue # Skip
                    # Do not consider player and frozen creatures.
                creature_list.append(child)
        else:
            # Check if basecreature
            if child is BaseCreature:
                creature_list.append(child)
        
    return creature_list
    
func get_block_list(world: Node) -> Array:
    var block_list: Array
    var world_children = world.get_children()
    for child in world_children:
        # Check if block
        if child is Block:
            block_list.append(child)
    return block_list
    
## -- Saving Data --

func save_game(game_data: Dictionary, slot_number: int = Vars.save_slot_number) -> bool:
    var save_path = _get_save_path(slot_number)
    if save_path.is_empty():
        return false

    var file = FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        printerr("Failed to open save file for writing: ", save_path, " - ", FileAccess.get_open_error())
        return false

    var json_string = JSON.stringify(game_data, "\t")
    file.store_string(json_string)
    file.close()

    print("Game saved successfully to: ", save_path)
    return true
    
func save_player(player_data: Dictionary, save_slot_number: int = Vars.save_slot_number) -> bool:
    var player_path = _get_player_path(save_slot_number)
    if player_path.is_empty():
        return false

    var file = FileAccess.open(player_path, FileAccess.WRITE)
    if file == null:
        printerr("Failed to open player file for writing: ", player_path, " - ", FileAccess.get_open_error())
        return false

    var json_string = JSON.stringify(player_data, "\t")
    file.store_string(json_string)
    file.close()

    print("Player saved successfully to: ", player_path)
    return true
    
func save_world(world_data: Dictionary, world_name: String, save_slot_number: int = Vars.save_slot_number) -> bool:
    var world_path = _get_world_path(world_name, save_slot_number)
    if world_path.is_empty():
        return false

    var file = FileAccess.open(world_path, FileAccess.WRITE)
    if file == null:
        printerr("Failed to open world file for writing: ", world_path, " - ", FileAccess.get_open_error())
        return false

    var json_string = JSON.stringify(world_data, "\t")
    file.store_string(json_string)
    file.close()

    print("World saved successfully to: ", world_path)
    return true
    
func save_creature(creature_data: Dictionary, creature_name: String) -> bool:
    var creature_path = _get_creature_path(creature_name)
    if creature_path.is_empty():
        return false

    var file = FileAccess.open(creature_path, FileAccess.WRITE)
    if file == null:
        printerr("Failed to open body file for writing: ", creature_path, " - ", FileAccess.get_open_error())
        return false

    var json_string = JSON.stringify(creature_data, "\t")
    file.store_string(json_string)
    file.close()

    print("Creature data saved successfully to: ", creature_path)
    return true
    
func save_symbol(symbol_data: Dictionary, symbol_name: String) -> bool:
    var symbol_path = _get_symbol_path(symbol_name)
    if symbol_path.is_empty():
        return false

    var file = FileAccess.open(symbol_path, FileAccess.WRITE)
    if file == null:
        printerr("Failed to open symbol file for writing: ", symbol_path, " - ", FileAccess.get_open_error())
        return false

    var json_string = JSON.stringify(symbol_data, "\t")
    file.store_string(json_string)
    file.close()

    print("Symbol data saved successfully to: ", symbol_path)
    return true
    
## -- Appliance of Data --

func apply_world_data(world_data: Dictionary, world: World):
    if not world or not is_instance_valid(world):
        printerr("SaveManager - (apply_world_data) - Given world is invalid.")
        return
    
    var world_name = world.world_name
    var loaded_data = world_data
    
    if not loaded_data.is_empty(): # Check if the loaded data is not empty
        print("LOAD - Loaded data of world '", world_name, "'.")
          
        ## Delete all
        for creature in get_creature_list(world, true):
            if !creature.creature_type == "player":
                creature.queue_free()
        for block in get_block_list(world):
            block.queue_free()
        
        # Wait a frame for all of the old junk to be destroyed properly
        await get_tree().process_frame
        
        ## Handle World:
        if loaded_data.has("world_info"):
            var world_info_entry = loaded_data.get("world_info")
            var world_size = world_info_entry.get("world_size")
            var x = world_size.get("x")
            var y = world_size.get("y")
            world_size = Vector2(x, y)
            world.update_world_size(world_size)
            
            # BG Color
            var bg_color = world_info_entry.get("bg_color")
            var r = bg_color.get("r")
            var g = bg_color.get("g")
            var b = bg_color.get("b")
            var a = bg_color.get("a")
            world.update_bg_color(Color(r, g, b, a))
        
        ## Handle all
        
        # 1. Initialize a counter before the loop starts.
        var item_counter: int = 0

        for entry in loaded_data.values():
            item_counter += 1 # Increment the counter for each item we process.
            
            var entry_class = entry.get("class")
            
            if "BaseCreature" == entry.get("class") and entry.get("creature_type") != "player":
                handle_creature_entry(entry, world)
            elif "Block" == entry.get("class"):
                handle_block_entry(entry, world)
                
            if item_counter % 100 == 0:
                # If we've processed 100 items, pause the function and wait for the next frame.
                # This gives the engine a "breather" to update the screen and handle other things.
                await get_tree().process_frame
    else:
        print("LOAD - Failed to load data of world '", world_name, "'.")
        
func handle_creature_entry(entry, parent_world: Node):
    var creature_type = entry.get("creature_type")
    
    var creature_name = entry.get("creature_name")
    var max_hp = entry.get("max_hp")
    var hp = entry.get("hp")
    var creature_position = entry.get("creature_position")
    
    if not parent_world:
        return # Do not spawn if parent world is nonexistent
    
    var res_path = "res://scenes/creatures/" + creature_type + ".tscn"
    var creature = load_and_instance(creature_type, res_path)
            
    parent_world.add_child(creature)
    creature.c_setup_variables(creature_type, max_hp, hp)
    
    var x = creature_position.get("x")
    var y = creature_position.get("y")
    
    creature._worldly_position = Vector2(x, y)
    print("LOAD - BASE CREATURE: ", entry)
    
func handle_block_entry(entry, parent_world: Node):
    var block_type = entry.get("block_type")
    
    var block_name = entry.get("block_name")
    var block_position = entry.get("block_position")
    var x = block_position.get("x")
    var y = block_position.get("y")
    
    block_position = Vector2(x, y)
    
    if not parent_world:
        return # Do not spawn if parent world is nonexistent
        
    var BLOCK = load("res://scenes/blocks/" + block_type + ".tscn") # Check in files
    var block: Block = BLOCK.instantiate()
    
    ## Handle updating tile_map
    var block_grid_pos = round(block_position / Constants.tile_size)
    parent_world.current_tile_map[block_grid_pos] = block
    
    ## Handle Special Data and Block Properties:
    
    # Get Special data
    var special_data: Dictionary
    if entry.has("special_data"):
        special_data = entry.get("special_data")
    elif entry.has("pocket_dim_data"):
        special_data = entry.get("pocket_dim_data")
    elif entry.has("freeze_pod_data"):
        special_data = entry.get("freeze_pod_data")
    
    if "stored_data" in block and !special_data.is_empty():
        if special_data.has("frozen_obj_path") and special_data.get("frozen_obj_path"):
            block.frozen_obj_path = special_data.get("frozen_obj_path")
        if special_data.has("target_world_name") and special_data.get("target_world_name"):
            block.target_world_name = special_data.get("target_world_name")
        if special_data.has("turret_name") and special_data.get("turret_name"):     
            block.turret_name = special_data.get("turret_name")
            
    ## Add the block:
    parent_world.add_child(block)
    block.b_setup_variables(block_type, block_position)

## only ever call this function when initially loading stuff to place the player in the leftoff world.
func apply_player_data(player_data: Dictionary):
    var current_existing_player = WorldUtils.get_player_node(null)
    
    if not current_existing_player:
        printerr("func apply_player_data: 'current_existing_player' Player not found.")
        return
    
    var creature_name = player_data.get("creature_name")
    var max_hp = player_data.get("max_hp")
    var hp = player_data.get("hp")
    var parent_world = player_data.get("parent_world")
    var creature_position = player_data.get("creature_position")
    
    var target_world = WorldUtils.get_world_by_name(parent_world)
    
    var x = creature_position.get("x")
    var y = creature_position.get("y")
    
    await TransportManager.transport_from_to(current_existing_player, parent_world, Vector2(x, y))
    current_existing_player.c_setup_variables("player", max_hp, hp)
    
## -- Loading Data --

func load_game(slot_number: int = Vars.save_slot_number) -> Dictionary:
    var save_path = _get_save_path(slot_number)
    if save_path.is_empty():
        return {}

    if not FileAccess.file_exists(save_path):
        print("No save file found at: ", save_path)
        return {}

    var file = FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        printerr("Failed to open save file for reading: ", save_path, " - ", FileAccess.get_open_error())
        return {}

    var json_string = file.get_as_text()
    file.close()

    var json_result = JSON.parse_string(json_string)
    if json_result == null or not (json_result is Dictionary): 
        printerr("Failed to parse save file JSON or invalid format: ", save_path)
        return {}

    print("Game loaded successfully from: ", save_path)
    return json_result as Dictionary
    
func load_world(world_name: String, slot_number: int = Vars.save_slot_number) -> Dictionary:
    var world_path = _get_world_path(world_name, slot_number)
    if world_path.is_empty(): # World does not exist. Return empty.
        return {}

    if not FileAccess.file_exists(world_path):
        print("No world file found at: ", world_path)
        return {}

    var file = FileAccess.open(world_path, FileAccess.READ)
    if file == null:
        printerr("Failed to open world file for reading: ", world_path, " - ", FileAccess.get_open_error())
        return {}

    var json_string = file.get_as_text()
    file.close()

    var json_result = JSON.parse_string(json_string)
    if json_result == null or not (json_result is Dictionary): 
        printerr("Failed to parse world file JSON or invalid format: ", world_path)
        return {}

    print("World loaded successfully from: ", world_path)
    return json_result as Dictionary
    
func load_player(slot_number: int = Vars.save_slot_number) -> Dictionary:
    var player_path = _get_player_path(slot_number)
    if player_path.is_empty(): # Player does not exist. Return empty.
        return {}

    if not FileAccess.file_exists(player_path):
        print("No player file found at: ", player_path)
        return {}

    var file = FileAccess.open(player_path, FileAccess.READ)
    if file == null:
        printerr("Failed to open player file for reading: ", player_path, " - ", FileAccess.get_open_error())
        return {}

    var json_string = file.get_as_text()
    file.close()

    var json_result = JSON.parse_string(json_string)
    if json_result == null or not (json_result is Dictionary): 
        printerr("Failed to parse player file JSON or invalid format: ", player_path)
        return {}

    print("Player loaded successfully from: ", player_path)
    return json_result as Dictionary
    
func load_symbol(symbol_name: String) -> Dictionary:
    var symbol_path = _get_symbol_path(symbol_name)
    if symbol_path.is_empty(): # Symbol does not exist. Return empty.
        return {}

    if not FileAccess.file_exists(symbol_path):
        print("No symbol file found at: ", symbol_path)
        return {}

    var file = FileAccess.open(symbol_path, FileAccess.READ)
    if file == null:
        printerr("Failed to open symbol file for reading: ", symbol_path, " - ", FileAccess.get_open_error())
        return {}

    var json_string = file.get_as_text()
    file.close()

    var json_result = JSON.parse_string(json_string)
    if json_result == null or not (json_result is Dictionary): 
        printerr("Failed to parse symbol file JSON or invalid format: ", symbol_path)
        return {}

    print("Symbol loaded successfully from: ", symbol_path)
    return json_result as Dictionary
