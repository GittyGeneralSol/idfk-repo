extends Node2D

const HypocycloidGenerator = preload("res://scripts/shape_generators/HypocycloidGenerator.gd")

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    # Setter function for 'worldly_position'
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)
    # Getter function for 'worldly_position'
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

# --- Customize these parameters ---
@export var num_points: int = 4      # Number of cusps (n). Must be >= 3 for the 'squished' shape.
@export var circumrad: float = 15 # Corresponds to R = nr. This is the distance to the cusps.
@export var shape_color: Color = Color.ORANGE # Example color (pink)
@export var center_offset: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = -45 # Rotate the body

@export var points_body: PackedVector2Array # Accessed by deco

# --- Bullet Dynamics ---
@export var damage: float = 20.0
@export var collidible: bool = true # Whether it collides with blocks or not
@export var max_travel_distance: float = 1000.0 # Increased default distance, adjust as needed\

var _max_dist_before_hit: float = 70
var _travel_direction: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var _spawn_position: Vector2 # Stores the bullet's position at spawn
var _target: BaseCreature

func _ready() -> void:
    queue_redraw()
    _spawn_position = _worldly_position # Store the actual global spawn point

# --- NEW: Setup method to receive initial bullet properties ---
func setup_bullet(direction: Vector2, speed: float):
    _travel_direction = direction.normalized() # Ensure it's a unit vector
    _current_speed = speed
    rotation = _travel_direction.angle() + PI / 2.0


func _process(delta: float) -> void:
    handle_block_collision(_worldly_position)
    
    # Move the bullet in its travel direction at its speed, multiplied by delta for frame-rate independence.
    _worldly_position += _travel_direction * _current_speed * delta
    
    # Check distance from spawn point.
    if _worldly_position.distance_to(_spawn_position) >= max_travel_distance:
        queue_free()
        return
    
    # Check if target even exists:
    if not _target:
        return
    
    _max_dist_before_hit = circumrad
    # Check distance from target.
    if _worldly_position.distance_to(_target._worldly_position) <= _max_dist_before_hit:
        _target.hit(damage)
        queue_free()

func _draw():
    ## Forming the shapes
    var points_body: PackedVector2Array = HypocycloidGenerator.generate_hypocycloid_points(num_points, circumrad, 360, center_offset, rotation_deg)

    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polygon(points_body, [shape_color])
    else: push_error("draw_polygon() needs at least three points.")
    
func delayed_deletion(time: float):
    await get_tree().create_timer(time).timeout
    queue_free()

func set_color(new_color: Color):
    shape_color = new_color
    queue_redraw()

## -- Block Collision --
func handle_block_collision(pos_p: Vector2):
    ## Check if current position lands on a Block or not:
    if not _target or not collidible:
        return
        
    var self_pos = round(pos_p / Constants.tile_size)
    var spawn_pos = round(_spawn_position / Constants.tile_size)
    var tile_map = WorldUtils.get_parent_world_tile_map(self)
    
    if self_pos == spawn_pos:
        return ## Free clipping through spawning block
    
    if !tile_map.has(self_pos):
        return
    
    if tile_map[self_pos] is Block:
        queue_free()
    
