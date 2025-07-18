@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Positioning ---
var _worldly_position: Vector2 = Vector2.ZERO:
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = Constants.std_cr
@export var outline_width: float = 10.0
@export var shape_color: Color = Color.ROYAL_BLUE
@export var displacement: Vector2 = Vector2.ZERO
@export var rotation_deg: float = -45.0

@export var outline_correction: float = -2.5001
@onready var points_outline: PackedVector2Array

func _ready() -> void:
    ## Trigger the first draw:
    form_shape()
    queue_redraw()
    
func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        return
    
    var mouse_pos = get_global_mouse_position()
    var mouse_pos_snapped = snapped(mouse_pos, Vector2(Constants.tile_size, Constants.tile_size))
    _worldly_position = mouse_pos_snapped

func update_color(new_color: Color):
    shape_color = new_color
    queue_redraw()

func form_shape():
    ## Forming the shapes
    points_outline = PolygonGenerator.generate_polygon_points(num_points, circumrad + outline_width + 0 + outline_correction, displacement, rotation_deg) # Outline
    
    # Adding an extra point to outline array to form a closed shape:
    var extra_point = points_outline[0] # First point from array
    points_outline.append(extra_point)
    
func _draw():
    if not points_outline.size() < 2:
        draw_polyline(points_outline, shape_color, outline_width)
        
# --- Input ---
func _unhandled_input(event: InputEvent):
    if not Vars.build_mode and not Vars.destroy_mode:
        return

    # Filter to only care about ScreenTouch and MouseButton for initial press/release
    if not (event is InputEventScreenTouch or event is InputEventMouseButton):
        return
    
    # If InputEventMouseButton, only care about left clicks
    if event is InputEventMouseButton:
        if !event.button_index == MOUSE_BUTTON_LEFT:
            return

    # --- Handle Touch Press ---
    if event.is_pressed():
        var player_node = WorldUtils.get_player_node()
        var player_world: World = WorldUtils.get_parent_world(player_node)
        
        if Vars.build_mode:
            handle_build_mode(player_world, player_node)
        elif Vars.destroy_mode:
            handle_destroy_mode(player_world, player_node)
        
    # --- Handle Touch Release ---
    elif (event is InputEventScreenTouch or event is InputEventMouseButton) and !event.is_pressed():
        pass

func handle_build_mode(world: World, player: BaseCreature):
    var grid_pos = get_grid_pos_from_touch(world)
    handle_block_placement(world, player, grid_pos, "stone_block", {})

func handle_destroy_mode(world: World, player: BaseCreature):
    var grid_pos = get_grid_pos_from_touch(world)
    handle_block_removal(world, player, grid_pos)
    #handle_block_placement(world, player, grid_pos, "stone_block")

func get_grid_pos_from_touch(world: World) -> Vector2:
    if not is_instance_valid(world):
        return Vector2.ZERO

    var touch_pos = get_global_mouse_position() 
    var local_in_world_pos = WorldUtils.convert_global_to_local_pos(touch_pos, world)
    var grid_pos = round(local_in_world_pos / Constants.tile_size)
    
    return grid_pos

func handle_block_placement(world: World, player: BaseCreature, grid_pos: Vector2, selected_block: String = "turret_base", args: Dictionary = { "turret_name": "x_shooter" }):
    if not is_instance_valid(world) or not is_instance_valid(player):
        return
    
    if player.self_pos == grid_pos:
        return
    
    if !WorldUtils.pos_is_inside_rect(grid_pos, world.world_size):
        return
    
    var current_tile_map: Dictionary = world.current_tile_map
    
    if not current_tile_map.has(grid_pos):
        world.create_block(grid_pos, selected_block, args)

func handle_block_removal(world: World, _player: BaseCreature, grid_pos: Vector2):
    if not is_instance_valid(world) or not is_instance_valid(_player):
        return
    
    if !WorldUtils.pos_is_inside_rect(grid_pos, world.world_size):
        return
    
    var current_tile_map: Dictionary = world.current_tile_map
    
    if not current_tile_map.has(grid_pos):
        return
        
    world.remove_block(grid_pos)
    
