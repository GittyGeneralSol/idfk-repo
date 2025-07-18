extends Node2D

# class_name BaseCreature

## The base creature class used to define all creatures in IDFK.

enum MOVE_TYPE {
    SQUISH,
    SLIDE
}

## Audio:
const PLOP = preload("res://assets/Creatures/sfx/plop-pixabay.mp3")
const HP_BAR = preload("res://scenes/utility/hp_bar.tscn")

## Effects:
const COLORED_RECTS = preload("res://scenes/effects/colored_rects.tscn")
const CollisionAnimations = preload("res://scripts/utility/collision_animations.gd")

## Internal Flags:
@export var _setting_up_vars: bool = false:
    set(new_value):
        _setting_up_vars = new_value
        if _setting_up_vars == true and _current_move_tween:
            _current_move_tween.kill()
    get:
        return _setting_up_vars

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position
        
var self_pos: Vector2 = Vector2.ZERO:
    set(new_value):
        self_pos = new_value
    get:
        self_pos = round(_worldly_position / Constants.tile_size)
        return self_pos

## General:
@export var creature_type: String = "unspecified"
@export var dead: bool = false ## Kills Behavior and Blinking
@export var is_frozen: bool = false
@export var allow_moving: bool = true
@export var hit_box_circumrad: float = 70 # For bullets
@export var max_hp: float = 100
@export var hp: float = 100:
    # Setter function for 'hp'
    set(new_value):
        var original_hp = hp
        hp = clamp(new_value, 0, max_hp)
        if original_hp != hp: print("BaseCreature - ", creature_type.capitalize(), "'s HP changed from ", original_hp, " to ", hp)
        
        # Do not handle hp bar if setting up vars, initializing basically.
        if not _setting_up_vars:
            handle_hp_bar()
        else:
            # If setting up vars is true, delete child hp bar, if it exists.
            if self.has_node("Hp Bar"):
                get_node("Hp Bar").queue_free()
        
        if hp <= 0 and not dead:
            die()
        elif hp > 0: ## If hp is above zero
            dead = false
        elif original_hp > new_value: ## if damaged, but not dead, hit animation
            hit()

    # Getter function for 'hp'
    get:
        return hp
    
@export var move_step: float = Constants.tile_size
@export var displ_when_eye_targets: float = 7

## Body:
@onready var body_node: Node2D = $body
# Find apothem of body shape:
@onready var t = (360 / body_node.num_points) / 2 if ("num_points" in body_node) else null
@onready var apothem = cos(deg_to_rad(t)) * body_node.circumrad if ("circumrad" in body_node && "num_points" in body_node) else null

## Eyes:
@onready var eyes_node: Node2D = $eyes
@onready var st_eyelids_left_node: Node2D # Set if only standard two eyes
@onready var st_eyelids_right_node: Node2D # Set if only standard two eyes

## --- Collision and Movement ---
var collision_info: Dictionary = {
    "hitbox_gridsize": Vector2.ONE,
    "primary_movement": Vector4(20, 20, 20, 20),
    "secondary_movement": Vector4(10, 10, 10, 10),
    "x_squish_factor": 1.25,
    "y_squish_factor": 1.25
}

var movement_info: Dictionary = {
    "movement_type": MOVE_TYPE.SQUISH,
    "eye_movement": 7,
    "x_squish_factor": 1.25,
    "y_squish_factor": 1.25
}

# --- Child Body Parts ---
@onready var child_parts: Array:
    set(new_value): pass
    get(): var child_parts = get_child_parts(self); return child_parts

## --- Internals ---
var action_lock = null # A "lock" to prevent new actions. If it's not null, the player is busy.

# -- Internal interruptable Tweens --
var _current_death_tween: Tween
var _current_move_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass

# --- Body Parts and Saving ---
func get_child_parts(obj: Node) -> Array:
    var children = obj.get_children()
    var found_parts: Array = []
    for child in children:
        if child is BaseCreaturePart and child is not BaseCreatureEyelids and !child.procedurally_created:
            found_parts.append(child)
            var parts_of_part = get_child_parts(child)
            if parts_of_part:
                found_parts += parts_of_part
    return found_parts
    
func form_and_save_creature(desc: String = "Standard custom creature."):
    if Engine.is_editor_hint() or !self.is_node_ready():
        return
    
    # var creature_data = SaveManager._formulate_creature_data(self, desc) 
    # SaveManager.save_creature(creature_data, creature_type)
    
func is_able_to_move() -> bool:
    # This function will always check the CURRENT state of the variables.
    return (!dead and !is_frozen and allow_moving and !_setting_up_vars and action_lock == null and is_inside_tree())

func c_setup_variables(c_type: String, c_max_hp: float, c_hp: float, c_worldly_pos: Vector2 = _worldly_position, c_hitbox_cr: float = hit_box_circumrad):
    _setting_up_vars = true # Set flag to not trigger bs
    creature_type = c_type
    add_to_group(creature_type + "s")
    max_hp = c_max_hp
    hp = c_hp
    _worldly_position = c_worldly_pos
    hit_box_circumrad = c_hitbox_cr
    _setting_up_vars = false # Unset flag

func handle_hp_bar():
    var hp_bar: Node
    var percent = ( hp / max_hp ) * 100
    
    # Get Hp Bar
    if not self.has_node("Hp Bar"):
        hp_bar = HP_BAR.instantiate() # If no hp_bar, create one.
        hp_bar.filling_percent = percent
        hp_bar.position = Vector2(0, -125)
        add_child(hp_bar)
    else:
        hp_bar = get_node("Hp Bar")
        hp_bar.update_percent(percent)

## --- Death Section ---

func hit():
    if WorldUtils.is_in_player_world(self) and (!dead or hp <= 0.0): ## Only play hit sounds if the player is also in this world, and if creature is alive 
        SoundManager.play_one_shot_2d(self, PLOP, 4.5, 0.4, 0.3)

func die():
    dead = true ## Update flag
    await collapse_scale()
    
    var effects = COLORED_RECTS.instantiate()
    effects.rect_col = body_node.body_color
    get_parent_world().add_child(effects)
    effects.z_index = self.z_index -1
    effects._worldly_position = _worldly_position
    
    if creature_type != "player": queue_free()
    
func is_dead() -> bool:
    if dead: return true
    else:    return false
    
    # --- Tweening Functions ---
func tween_scale_to(target_scale: Vector2, time: float, ease_type: Tween.EaseType):
    # Kill any existing tween managed by this script
    if _current_death_tween and _current_death_tween.is_valid():
        _current_death_tween.kill()

    _current_death_tween = create_tween()
    _current_death_tween.set_ease(ease_type).set_trans(Tween.TRANS_ELASTIC)

    _current_death_tween.tween_property(self, "scale", target_scale, time)
    
    await _current_death_tween.finished

# --- Control Functions ---
func collapse_scale():
    if scale > Vector2.ZERO:
        await tween_scale_to(Vector2.ZERO, 0.5, Tween.EASE_IN)

func empower_scale():
    if scale < Vector2.ONE:
        tween_scale_to(Vector2.ONE, 0.5, Tween.EASE_OUT)

func play_plop():
    if WorldUtils.is_in_player_world(self): ## Only play plop sounds if the player is also in this world     
        SoundManager.play_one_shot_2d(self, PLOP, 1.5, 0.4)

func standard_two_eye_blink():
    if not (st_eyelids_left_node and st_eyelids_right_node):
        return
        
    # Create tweens
    var tween_left = create_tween()
    var tween_right = create_tween()
    
    # Animate from current openness to 0.0 (closed) over a period of 0.1 seconds:
    tween_left.tween_property(st_eyelids_left_node, "openness", 0.0, 0.1) # Left Eye
    tween_right.tween_property(st_eyelids_right_node, "openness", 0.0, 0.1) # Right Eye
    
    # Add a delay (hold closed for 0.1 seconds):
    tween_left.tween_interval(0.1) # Left Eye
    tween_right.tween_interval(0.1) # Right Eye
    
    # Animate from current current openness (0.0/closed) to 1.0 (open) over a period of 0.1 seconds:
    tween_left.tween_property(st_eyelids_left_node, "openness", 1.0, 0.1) # Left Eye
    tween_right.tween_property(st_eyelids_right_node, "openness", 1.0, 0.1) # Right Eye

func master_eye_blink():
    # Create tweens
    var tween_master = create_tween()
    
    # Animate from current master_openness to 0.0 (closed) over a period of 0.1 seconds:
    tween_master.tween_property(eyes_node, "master_openness", 0.0, 0.1)
    
    # Add a delay (hold closed for 0.1 seconds):
    tween_master.tween_interval(0.1)
    
    # Animate from current current master_openness (0.0/closed) to 1.0 (open) over a period of 0.1 seconds:
    tween_master.tween_property(eyes_node, "master_openness", 1.0, 0.1)

func move_behavior_standard():
    if not get_parent_world():
        return
        
    var random_move_numb = randi_range(1,5)
    
    match(random_move_numb):
        1:
            await move_squish_st(Vector2.UP, 0.2, 4.0)
        2:
            await move_squish_st(Vector2.DOWN, 0.2, 4.0)
        3:
            await move_squish_st(Vector2.LEFT, 0.2, 4.0)
        4:
            await move_squish_st(Vector2.RIGHT, 0.2, 4.0)
        5:
            await idle(8.0)

    if is_able_to_move() : move_behavior_standard() # For Looping
    
## --- AStar ---
    
func get_path_steps(beg_grid_pos: Vector2i, target_grid_pos: Vector2i) -> PackedVector2Array:
    var astar_grid = WorldUtils.get_parent_world_astar_grid(self)
    
    if not astar_grid:
        return []
        
    if not (pos_is_inside_rect(target_grid_pos,  WorldUtils.get_parent_world(self).world_size)):
        return []
        
    if not (astar_grid.is_in_bounds(target_grid_pos.x, target_grid_pos.y) and (astar_grid.is_in_bounds(beg_grid_pos.x, beg_grid_pos.y))):
        return []

    
    if astar_grid.is_point_solid(target_grid_pos):
        print("CREATURE: Target Position is in or is a solid.")
        return []
        
    var series_of_steps = astar_grid.get_id_path(beg_grid_pos, target_grid_pos)
    return series_of_steps

# The main entry point for this behavior. It's just a simple loop.
func move_behavior_astar(target_object: Node = null) -> void:
    while is_able_to_move():
        # 1. Plan the next full path.
        var path: PackedVector2Array = await _plan_path(target_object)
        
        # 2. If planning was successful, execute the movement along the path.
        print("path: ", path)
        if not path.is_empty():
            await _execute_path(path, target_object)
        
        # 3. Brief pause before planning the next move.
        await idle(0.5)

# --- Planning Phase ---

# Determines the target and calculates a path to it. Returns an empty array on failure.
func _plan_path(target_object: Node) -> PackedVector2Array:
    # Randomly decide to idle for a bit.
    if randi_range(1, 5) == 5:
        await idle(8.0)
        # Check for movability after long idle, in case state changed.
        if not is_able_to_move(): return []

    # Get a valid target position.
    var target_pos: Vector2 = _get_target_position(target_object)
    print("target_pos: ", target_pos)
    if target_pos == self_pos: # No need to move if we're already there.
        await idle(2.0)
        return []

    # Find the path using A*.
    var path: PackedVector2Array = get_path_steps(self_pos, target_pos)
    if path.is_empty(): # Pathfinding failed.
        await idle(2.0)
        return []
    
    ## Debug marker.
    # get_parent_world().create_marker(target_pos)
    
    return path

# --- Execution Phase ---

# Moves the creature tile by tile along a pre-calculated path.
func _execute_path(path: PackedVector2Array, target_object: Node) -> void:
    # Iterate through each segment of the path.
    # We start from index 1 because path[0] is the starting position.
    for i in range(1, path.size()):
        if not is_able_to_move(): return
        
        var start_point = self_pos
        var end_point = path[i]
        
        # Execute the moves for this single horizontal or vertical segment.
        var success: bool = await _execute_path_segment(start_point, end_point)
        
        # If any segment fails (e.g., we hit a wall), abort this path immediately
        # and let the main loop re-plan from our new position.
        if not success:
            print("CREATURE: Path execution failed. Re-planning.")
            await idle(0.5)
            return

# Handles a single straight-line segment of the path (e.g., moving 5 tiles right).
func _execute_path_segment(start_pos: Vector2, end_pos: Vector2) -> bool:
    var delta = end_pos - start_pos
    var move_dir: Vector2
    var num_steps: int

    if delta.x != 0 and delta.y == 0: # Horizontal
        move_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
        num_steps = absi(delta.x)
    elif delta.y != 0 and delta.x == 0: # Vertical
        move_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
        num_steps = absi(delta.y)
    else:
        printerr("CREATURE: Path contains invalid diagonal or zero-length segment.")
        return false # Signal failure

    # Execute the individual tile-by-tile moves.
    for _i in range(num_steps):
        if not is_able_to_move(): return false
        
        var pos_before_move = self_pos
        await move_squish_st(move_dir, 0.2, 1.0)
        
        # Check if we got stuck.
        if self_pos == pos_before_move:
            return false # Signal failure
            
    return true # Signal success


# --- Helper Functions ---

# Determines a valid target position, either random or from a target object.
func _get_target_position(target_object: Node) -> Vector2:
    if is_instance_valid(target_object):
        return target_object.self_pos
        
    # No target, so find a random position.
    var world = get_parent_world()
    var world_bounds = world.world_size / 2.0
    var effective_bounds = world_bounds - Vector2.ONE
    var step_range = clamp(Vector2(10, 10), -effective_bounds, effective_bounds)

    var move_x = randi_range(-step_range.x, step_range.x)
    var move_y = randi_range(-step_range.y, step_range.y)
    var target_pos = self_pos + Vector2(move_x, move_y)
    
    # Clamp the position to be within the world bounds.
    target_pos = clamp(target_pos, -effective_bounds, effective_bounds)
    
    return target_pos
    
## --- End AStar ---
    
func move_regular_st(dir: String = "up", delay_after_move: float = 1.0):
    var tween_move = create_tween()
    var tween_eye_move = create_tween()
    var target_pos: Vector2 = Vector2.ZERO
    var eye_target_pos: Vector2 = Vector2.ZERO
    
    ## Direction Handling:
    
    match(dir):
        "up":
            ## UP
            target_pos = Vector2(position.x, position.y - move_step)
            eye_target_pos = Vector2(0, -displ_when_eye_targets)
        "down":
            ## DOWN
            target_pos = Vector2(position.x, position.y + move_step)
            eye_target_pos = Vector2(0, displ_when_eye_targets)
        "left":
            ## LEFT
            target_pos = Vector2(position.x - move_step, position.y)
            eye_target_pos = Vector2(-displ_when_eye_targets, 0)
        "right":
            ## RIGHT
            target_pos = Vector2(position.x + move_step, position.y)
            eye_target_pos = Vector2(displ_when_eye_targets, 0)
            
    if !dead:
        # Animate whole system moving from current position to move_step pixels left over a period of 1 second:
        tween_move.tween_property(self, "_worldly_position", target_pos, 1) # Move Whole System
    
        # Animate eye system moving displ_when_eye_targets pixels left relative to origin over a period of 0.1 second:
        tween_eye_move.tween_property(eyes_node, "position", eye_target_pos, 0.1) # Move eyes_node
    else:
        print(self, " is dead.")
        
    # Delay of varying secs before this dood does anything else
    await get_tree().create_timer(delay_after_move).timeout
        
func move_squish_st(dir: Vector2, time_to_move: float = 0.2, aftermove_delay: float = 1.0):
    if not is_able_to_move():
        return # Do not move
        
    ## At the start of any move, create a lock.
    action_lock = self
    
    ## Get squishing info:
    var col_x_factor = collision_info.get("x_squish_factor", 1.25)
    var col_y_factor = collision_info.get("y_squish_factor", 1.25)
    var move_x_factor = movement_info.get("x_squish_factor", 1.25)
    var move_y_factor = movement_info.get("y_squish_factor", 1.25)
    
    ## Initialize vars
    var target_pos: Vector2 = Vector2.ZERO
    var move_squish: Vector2 = Vector2.ONE
    var eye_target_pos: Vector2 = Vector2.ZERO
    
    ## Direction Handling:
    target_pos = position + dir * move_step
    eye_target_pos = dir * movement_info.get("eye_movement", 7)
    
    if dir.x != 0: # Horizontal move
        move_squish = Vector2(1.0 * move_x_factor, 1.0 / move_x_factor)
    elif dir.y != 0: # Vertical move
        move_squish = Vector2(1.0 / move_y_factor, 1.0 * move_y_factor)
    
    ## Calibrate Target Position
    # Make sure creature always ends up in center of tiles:
    target_pos.x = snapped(target_pos.x, move_step)
    target_pos.y = snapped(target_pos.y, move_step)
    
    # Make sure creature always ends up within the bounds of the world:
    var world_size_p = get_parent_world().world_size_p
    target_pos.x = clamp(target_pos.x, -world_size_p.x/2, world_size_p.x/2)
    target_pos.y = clamp(target_pos.y, -world_size_p.y/2, world_size_p.y/2)
    
    ## Collision check:
    var collision_detected = check_pos_for_collision(dir)
    
    ## --- Process the Check Results ---
    if collision_detected:
        print("Collision with block detected! Cannot move there.")
        await block_collision(dir, time_to_move, eye_target_pos, move_squish)
        
        # Aftermove Cooldown
        await get_tree().create_timer(aftermove_delay).timeout
        
        ## End: 
        action_lock = null
        return
        
    ## If we are here, no collision was detected.
    print("Move is clear of blocks.")
    
    ## --- Movement ---

    # Create tweeners
    var tween_scale = create_tween()
    var tween_eye_move = create_tween()
    
    # Play plop sound:
    play_plop()
    
    ## Animation:
    await move_squish_animation(target_pos, eye_target_pos, time_to_move, move_squish)
    
    # Aftermove Cooldown
    await get_tree().create_timer(aftermove_delay).timeout
    
    ## End: 
    action_lock = null
    
func move_squish_animation(target_pos: Vector2, eye_target_pos: Vector2, time_to_move: float, move_scaling: Vector2):
    # Kill any existing tween managed by this script
    if _current_move_tween and _current_move_tween.is_valid():
        _current_move_tween.kill()
        
    # Create tweeners
    var _current_scale_tween = create_tween()
    var _current_eye_tween = create_tween()
    
    _current_move_tween = create_tween()
    
    # Animate BODY moving from current position to move_step pixels left over a period of 0.2 second:
    _current_move_tween.tween_property(self, "_worldly_position", target_pos, time_to_move) # Move Whole System
    
    # Squish the whole system from current scale to 20% squished:
    _current_scale_tween.tween_property(self, "scale", move_scaling, time_to_move/2)
    
    # Restore the whole system to original shape in half the time it takes to move:
    _current_scale_tween.tween_property(self, "scale", Vector2(1, 1), time_to_move/2)

    # Animate eye system moving displ_when_eye_targets pixels relative to origin over a period of 0.1 second:
    _current_eye_tween.tween_property(eyes_node, "position", eye_target_pos, 0.1) # Move eyes_node
    
    await _current_move_tween.finished

func block_collision(direction: Vector2, time_to_move: float, eye_target_pos: Vector2, move_squish_vector: Vector2): # Renamed scale arg
    if not self:
        return
    
    var col_info = get("collision_info")
    if dead or not col_info:
        return
    
    # Get the primary and secondary movement vectors:
    var primary_movement: Vector4 = col_info.get("primary_movement", Vector4(20, 20, 20, 20))
    var secondary_movement: Vector4 = col_info.get("secondary_movement", Vector4(10, 10, 10, 10))
    var x_factor = col_info.get("x_squish_factor", 1.25)
    var y_factor = col_info.get("y_squish_factor", 1.25)
    
    var primary_dist_to_move: float
    var secondary_dist_to_move: float
    var squish_vector: Vector2 # Collision Squish Vector
    match(direction):
        Vector2.UP:
            primary_dist_to_move = primary_movement.x
            secondary_dist_to_move = secondary_movement.x
            squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.DOWN:
            primary_dist_to_move = primary_movement.y
            secondary_dist_to_move = secondary_movement.y
            squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.LEFT:
            primary_dist_to_move = primary_movement.z
            secondary_dist_to_move = secondary_movement.z
            squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
        Vector2.RIGHT:
            primary_dist_to_move = primary_movement.w
            secondary_dist_to_move = secondary_movement.w
            squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
  
    ## 1. Animate CREATURE moving towards wall
    # Calculate target pos
    var original_pos: Vector2 = _worldly_position # Use _worldly_position for the bump
    var max_displ = direction * primary_dist_to_move
    var target_pos = original_pos + max_displ
    
    await move_squish_animation(target_pos, eye_target_pos, time_to_move, move_squish_vector)
    print(creature_type.capitalize(), " - DIST_TO_MOVE: ", primary_dist_to_move, " - ORIGINAL POS: ", original_pos, " - WALL/TARGET POS: ", target_pos, " - ACTUAL MEASURED FINAL POS: ", _worldly_position)
    
    ## 2. Animate CREATURE scaling plus creature moving forward INTO the wall
    # Calculate target pos
    var next_to_wall_pos: Vector2 = _worldly_position
    max_displ = direction * secondary_dist_to_move/2
    target_pos = next_to_wall_pos + max_displ
    
    var collision_tween = create_tween()
    collision_tween.tween_property(self, "scale", squish_vector, time_to_move/2.0)
    collision_tween.parallel().tween_property(self, "_worldly_position", target_pos, time_to_move/2.0)
    
    ## 3. Add a short delay (hold the bump/squish)
    collision_tween.tween_interval(0.2)

    ## 4. Animate CREATURE's scale normalizing and creature going back to being against the wall and not in
    collision_tween.tween_property(self, "scale", Vector2(1, 1), time_to_move/2.0)
    collision_tween.parallel().tween_property(self, "_worldly_position", next_to_wall_pos, time_to_move/2.0)
    await collision_tween.finished
    if not self: return
    
    # Hold..
    #await object.get_tree().create_timer(0.2).timeout
    #if not object: return
    
    ## 5. Animate CREATURE moving AWAY FROM wall
    # Calculate target pos
    var move_away_from_wall_tween = create_tween()
    move_away_from_wall_tween.tween_property(self, "_worldly_position", original_pos, time_to_move/2.0)
    await move_away_from_wall_tween.finished
 
func check_pos_for_collision(dir: Vector2) -> bool:
    var hitbox_gridsize = collision_info.get("hitbox_gridsize", Vector2.ONE)
    if hitbox_gridsize != Vector2.ONE:
        return check_rectangular_area_for_collision(dir, hitbox_gridsize)
    
    ## Update tile_map:
    var current_tile_map: Dictionary = get_parent_world_tile_map()
    
    var check_pos: Vector2 = self_pos + dir
    var world_size = get_parent_world().world_size
    
    # World Boundary check
    if !pos_is_inside_rect(check_pos, world_size):
        return true
            
    if current_tile_map.has(check_pos):    
        if not current_tile_map[check_pos]:
            return false
            
        if current_tile_map[check_pos] is Block:
            return true
        else: return false
    else:
        return false
    
func pos_is_inside_rect(check_pos: Vector2i, grid_size: Vector2i) -> bool:
    var x = grid_size.x/2
    var y = grid_size.y/2
    
    if abs(check_pos.x) > x:
        return false
    
    if abs(check_pos.y) > y:
        return false
        
    return true

func check_rectangular_area_for_collision(
    move_direction_grid: Vector2, # The direction the body will move (e.g., Vector2i(1,0))
    body_size_tiles: Vector2 # The (width, height) of the creature's body in tiles
) -> bool:
    
    ## Update tile_map (assuming this works implicitly with 'self'):
    var current_tile_map: Dictionary = WorldUtils.get_parent_world_tile_map(self)
    var parent_world = WorldUtils.get_parent_world(self) # Get parent world for its bounds

    if not is_instance_valid(parent_world):
        printerr("ERROR: World map data (tile_map or parent_world) not found for collision check.")
        return true # Assume collision/blocked if world data is missing


    # Calculate world boundaries from parent_world.world_size
    # These max values represent the highest *inclusive* valid grid coordinate.
    var world_bounds_x_min = floori(-parent_world.world_size.x / 2.0)
    var world_bounds_x_max = floori(parent_world.world_size.x / 2.0) - 1 
    var world_bounds_y_min = floori(-parent_world.world_size.y / 2.0)
    var world_bounds_y_max = floori(parent_world.world_size.y / 2.0) - 1 

    # Calculate the top-left grid coordinate of the creature's bounding box
    # If self_pos is the center, this adjusts to the top-left.
    var half_body_x = floori(body_size_tiles.x / 2.0)
    var half_body_y = floori(body_size_tiles.y / 2.0)
    
    var current_top_left_grid_pos = self_pos - Vector2(half_body_x, half_body_y)
    
    # Calculate the top-left grid coordinate of the creature's *next* bounding box (after moving)
    var next_top_left_grid_pos = current_top_left_grid_pos + move_direction_grid

    # Iterate through all grid cells that the creature's body would occupy at its *next* position.
    for x_offset in range(body_size_tiles.x):
        for y_offset in range(body_size_tiles.y):
            var check_pos_grid = next_top_left_grid_pos + Vector2(x_offset, y_offset)

            # --- Check 1: World Boundary Collision ---
            if check_pos_grid.x < world_bounds_x_min or check_pos_grid.x > world_bounds_x_max or \
               check_pos_grid.y < world_bounds_y_min or check_pos_grid.y > world_bounds_y_max:
                # If any part of the body would go out of bounds, it's considered a collision.
                return true 

            # --- Check 2: Block Collision (similar to your existing check_pos_for_collision) ---
            # Always use .has() before accessing dictionary elements to prevent errors if key doesn't exist.
            if current_tile_map.has(check_pos_grid) and current_tile_map[check_pos_grid]:
                if current_tile_map[check_pos_grid] is Block:
                    # If a Block is found in any of the checked positions, it's a collision.
                    return true
    # If the loops complete without finding any collisions, the path is clear.
    return false

func get_parent_world() -> Node:
    ## Check two ancestors up:
    if get_parent():
        if get_parent() is World: return get_parent()
        elif get_parent() is not World and get_parent().get_parent() and get_parent().get_parent() is World: return get_parent().get_parent()
        else: return null
    else: return null
    
func get_parent_world_tile_map() -> Dictionary:
    if get_parent_world() and get_parent_world().current_tile_map: return get_parent_world().current_tile_map
    else: return {}

func is_player_world() -> bool:
    # Check to see if this world is a world with the player or not.
    if get_parent_world() and get_parent_world().has_node("Player"): return true
    else: return false
    
func idle(idle_time: float = 8.0):
    if idle_time <= 6.0:
        if get_tree():
            await get_tree().create_timer(idle_time).timeout
        return
    
    # Create ONE tween object for the entire idle sequence
    var idle_tween = create_tween()
    
    idle_tween.tween_property(eyes_node, "position", Vector2.ZERO, 0.1)
    
    print("Idling!")

    # --- First Eye Move ---
    # Calculate the target for the first move
    # Use randi_range for actual randomness!
    var random_look_dir_numb_1 = randi_range(1, 4) 
    var eye_target_pos_1 = eye_target_vector(random_look_dir_numb_1)

    # Add the first tween step to the single tween object
    # This will happen AFTER the move back to center
    idle_tween.tween_property(eyes_node, "position", eye_target_pos_1, 0.1)

    print("Just set up first eye move! Target Vector: ", eye_target_pos_1)

    # --- Delay 1 ---
    # Add the delay step to the SAME tween object.
    # This delay will start *after* the first tween_property step finishes.
    idle_tween.tween_interval(idle_time / 2.0) # Use 2.0 for float division

    # --- Second Eye Move ---
    # Calculate the target for the second move
    # Use randi_range for actual randomness!
    var random_look_dir_numb_2 = randi_range(1, 4) 
    var eye_target_pos_2 = eye_target_vector(random_look_dir_numb_2)

    # Add the second tween step to the SAME tween object
    # This will happen AFTER the first tween_interval finishes.
    idle_tween.tween_property(eyes_node, "position", eye_target_pos_2, 0.1)

    print("Just set up second eye move! Target Vector: ", eye_target_pos_2)

    # --- Final Delay ---
    # Add the final delay step to the SAME tween object
    # This delay will start after the second tween_property finishes.
    idle_tween.tween_interval(idle_time / 2.0) # Use 2.0 for float division

    await idle_tween.finished
    # If you await it here, any code *after* calling idle() will wait for the full sequence.
    # If you don't await it here, the idle() function finishes executing immediately (bad)
    
    
func eye_target_vector(dir_numb: int = 1)  -> Vector2:
    var eye_target_vector: Vector2 = Vector2.ZERO
    match(dir_numb):
        1:
            eye_target_vector = Vector2(0, -displ_when_eye_targets) ## UP
        2:
            eye_target_vector = Vector2(0, displ_when_eye_targets) ## DOWN
        3:
            eye_target_vector = Vector2(-displ_when_eye_targets, 0) ## LEFT
        4:
            eye_target_vector = Vector2(displ_when_eye_targets, 0) ## RIGHT
            
    return eye_target_vector 
    
func get_grid_pos(pos_p: Vector2 = _worldly_position):
    var grid_pos = round(pos_p / Constants.tile_size)
    return grid_pos
