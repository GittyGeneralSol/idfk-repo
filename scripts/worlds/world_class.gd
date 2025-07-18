@tool

extends Node2D

class_name World

## General Data:
@export var world_size: Vector2 = Vector2(4, 4)
@onready var world_readied: bool = false
@onready var world_size_p = world_size * Constants.tile_size ## World size in pixels
@onready var number_of_observers: int = 0 ## Total number of pocket dim boxes etc observing this world.
@onready var current_tile_map: Dictionary = {}
@onready var astar_grid: AStarGrid2D = AStarGrid2D.new()
@onready var background: Node2D = $Background

## Backgrounds:
@export var bg_color: Color = Color.DIM_GRAY - Color(0.2, 0.2, 0.2, 0.0)
@onready var bg_size = world_size * Constants.tile_size + Vector2(Constants.tile_size, Constants.tile_size)

# --- Loaded Scenes ---
# Reuse already loaded scenes, no need to reload
var _loaded_scenes: Dictionary = {}

## Objects:
const STARPOUCH = preload("res://scenes/objects/starpouch.tscn")

## Turrets:
const SHIELD = preload("res://scenes/turrets/shield.tscn")
const X_SHOOTER = preload("res://scenes/turrets/x_shooter.tscn")

## Misc:
const SELECTOR = preload("res://scenes/utility/selector.tscn")

func _ready() -> void:
    WorldUtils.connect("world_created", Callable(self, "on_world_readied"))
    add_to_group("worlds")
    background._setup_bg()
    initialize_astar_grid()

func on_world_readied(world_name: String, world_node: World):
    if world_node == self:
        world_readied = true
        
func handle_selector():
    if not Vars.in_any_mode():
        # Delete selector
        if self.has_node("Selector"):
            get_node("Selector").queue_free()
            return
    
    var selector: Node
    # Get Selector
    if not self.has_node("Selector"):
        selector = SELECTOR.instantiate() # If no selector, create one.
        selector.z_as_relative = true
        selector.z_index = Constants.selector_z_order
        add_child(selector)
    else:
        selector = get_node("Selector")
        
        if Vars.build_mode:
            selector.update_color(Color.ROYAL_BLUE)
        if Vars.destroy_mode:
            selector.update_color(Color.CRIMSON)

func create_block(grid_pos: Vector2, block_name: String, argument_dict: Dictionary = {}) -> Block:
    var block : Node
    
    if not block_name:
        print("WORLD_CLASS - Given block_name invalid. Block_name: ", block_name)
        return
    
    # Instantiate the block scene:    
    var scene_path = "res://scenes/blocks/" + block_name + ".tscn"
    block = load_and_instance(block_name, scene_path)
    
    if not block:
        printerr("WORLD_CLASS - Instatiated block invalid. Block_name: ", block_name)
        return
    
    ## Set given props
    add_child(block) # Add Child Early to override ready func's default values
    block.name = block_name.capitalize()
    block.position = grid_pos * Constants.tile_size
    
    # Argument dict -- for assigning specific properties.
    if argument_dict:
        for prop in argument_dict.keys():
            var value = argument_dict.get(prop)
            block.set(prop, value)
    
    ## Update World State
    current_tile_map[grid_pos] = block
    astar_grid.set_point_solid(grid_pos, true)
    
    # Update surrounding blocks
    if world_readied:
        update_surrounding_blocks(grid_pos)
        
    # Return
    return block
    
func create_creature(grid_pos: Vector2, creature_type: String, argument_dict: Dictionary = {}) -> BaseCreature:
    var creature: BaseCreature
    
    if not creature_type:
        print("WORLD_CLASS - Given creature_type invalid. Creature_type: ", creature_type)
        return
    
    # Instantiate the creature scene:    
    var scene_path = "res://scenes/creatures/" + creature_type + ".tscn"
    creature = load_and_instance(creature_type, scene_path)
    
    if not creature:
        printerr("WORLD_CLASS - Instatiated creature invalid. Creature_type: ", creature_type)
        return
    
    ## -- Set Pos --
    var pos_p = grid_pos * Constants.tile_size
    creature.position = pos_p
    
    # Do not set parameters in editor.
    if Engine.is_editor_hint():
        add_child(creature)
        return creature
    
    ## --- Set Parameters ---
    add_child(creature)
    
    # Argument dict -- for assigning specific properties.
    if argument_dict:
        for prop in argument_dict.keys():
            var value = argument_dict.get(prop)
            creature.set_custom(prop, value)
    
    creature.set_setting_up_vars(false) # Unset flag
    
    # Return
    return creature
    
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
        printerr("WORLD_CLASS ERROR: FAILED to load PackedScene with path '", scene_path, "'. Given scene_name: ", scene_name)
        return null

    # Instantiate and return
    var instance = scene.instantiate()
    
    if not is_instance_valid(instance):
        printerr("WORLD_CLASS ERROR: FAILED to instantiate scene with path '", scene_path, "'. Given scene_name: ", scene_name)
        return null

    return instance

    
func remove_block(grid_pos: Vector2) -> String:
    if not current_tile_map.has(grid_pos):
        return "null"
    
    var block: Block = current_tile_map.get(grid_pos)
    
    if not is_instance_valid(block):
        return "null"
        
    var block_type = block.block_type
    
    # Remove the block:
    block.queue_free()
    current_tile_map.erase(grid_pos)
    astar_grid.set_point_solid(grid_pos, false)
    
    ## Update surrounding blocks
    if world_readied:
        update_surrounding_blocks(grid_pos)
    
    # Return the type of the block we just removed
    return block_type
    
func update_surrounding_blocks(grid_pos: Vector2) -> Array[Block]:
    var updated_blocks: Array[Block]
    var surrounding_block_dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
                                  Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
    
    for i in range(surrounding_block_dirs.size()):
        var block_pos = surrounding_block_dirs[i] + grid_pos
        
        if not current_tile_map.has(block_pos):
            continue # Skip
        
        var block = current_tile_map[block_pos]
        
        if not is_instance_valid(block):
            continue # Skip
        
        updated_blocks.append(block)
        block.update_block()
        
    return updated_blocks
    
    
func create_marker(target_pos: Vector2i):
    var target_pos_p = target_pos * Constants.tile_size
    var marker = load_and_instance("cirangle", "res://scenes/creatures/cirangle.tscn")
    marker.dead = true
    marker.is_frozen = true
    marker.process_mode = Node.PROCESS_MODE_DISABLED
    marker.scale /= 4
    add_child(marker)
    marker._worldly_position = target_pos_p
    
    await get_tree().create_timer(2.0).timeout
    if is_instance_valid(marker):
        marker.queue_free()

func initialize_astar_grid():
    var parent_world_size = self.world_size
    var x_size = parent_world_size.x / 2
    var y_size = parent_world_size.y / 2
    
    astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar_grid.region = Rect2i(
        floori(-x_size), floori(-y_size), # Start X, Start Y
        ceilf(parent_world_size.x + 1), ceilf(parent_world_size.y + 1)) # Width, Height
    astar_grid.cell_size = Vector2(Constants.tile_size, Constants.tile_size)
    astar_grid.set_jumping_enabled(true)
    
    astar_grid.update()
    astar_grid.size
    
func update_world_size(new_size: Vector2):
    print("WORLD_CLASS - UPDATED WORLD_SIZE FROM ", world_size, " TO ", new_size)
    world_size = new_size
    world_size_p = world_size * Constants.tile_size ## World size in pixels
    background._setup_bg()

func update_bg_color(new_col: Color):
    print("WORLD_CLASS - UPDATED BG_COL FROM ", bg_color, " TO ", new_col)
    bg_color = new_col
    background._setup_bg()
