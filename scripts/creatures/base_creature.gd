extends Node2D

class_name BaseCreature

enum MOVE_TYPE { SQUISH, SLIDE }

# -- Audio --
const PLOP = preload("res://assets/Creatures/sfx/plop-pixabay.mp3")

# -- Spawnables & Preloaded Effects --
const HP_BAR = preload("res://scenes/utility/hp_bar.tscn")
const COLORED_RECTS = preload("res://scenes/effects/colored_rects.tscn")

## --- Flags ---
var dead: bool = false ## Kills Behavior and Blinking
var is_frozen: bool = false
var allow_moving: bool = true

## --- Positioning ---
var _worldly_position: Vector2 = Vector2.ZERO:
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

### --- Main Data Objects ---
var params: Dictionary:
    set(v):
        if params == v:
            return
            
        params = v
        if is_node_ready():
            update_from_params(params)

# --- General Data ---
var creature_type: String = "unspecified"
            
## --- Child Parts ---
var body_node: BaseCreatureMainBody
var eyeish_nodes: Array[BaseCreaturePart]

## --- Internal ---
# -- Internal Flags --
var _setting_up_vars: bool = false:
    set(new_value):
        _setting_up_vars = new_value
        if _setting_up_vars == true and _current_move_tween:
            _current_move_tween.kill()
    get:
        return _setting_up_vars
    
# -- Internal interruptable Tweens --
var _current_death_tween: Tween
var _current_move_tween: Tween
var _current_eyeish_tween: Tween # Tweens over eyeish nodes

## --- Stored CreatureLogics ---
# -- Health --
var _health_logic: CreatureHealth
var _health_info: Dictionary = {
    "initial_hp": 100,
    "max_hp": 100
}

# -- Blocking Actions / Movement --
var _action_logic: CreatureMover
var _movement_info: Dictionary = {
    "move_type": CreatureMover.MoveType.SQUISH,
    "move_step": Constants.tile_size,
    "move_time": 0.2,
    "aftermove_delay": 0.2,
    "eye_movement": 7,
    "x_squish_factor": 1.25,
    "y_squish_factor": 1.25
}

var _collision_info: Dictionary = {
    "hitbox_gridsize": Vector2.ONE,
    "hitbox_radius":  70, # For bullets
    "primary_movement": Vector4(20, 20, 20, 20),
    "secondary_movement": Vector4(10, 10, 10, 10),
    "x_squish_factor": 1.25,
    "y_squish_factor": 1.25
}

# -- AI --
var _ai_logic: CreatureAI
var _ai_info: Dictionary = {
    "behavior_loop": "pathfinding"
}

# -- Blinking --
var _blinker_logic: CreatureBlinker
var _blinking_info: Dictionary = {
    "blink_loop": "ranged",
    "min_interval": 3.0,
    "max_interval": 4.0
}

# -- Animation --
# -- For Premade Additional Animations --
var anim_players: Dictionary[String, CreatureAnimator]
var _animation_info: Array[Dictionary] = [
    {
        "animation": "",
        "custom_blend": -1,
        "custom_speed": 1.0,
        "start_delay": 0.0
    }
]

## --- Ready & Creature Parameters ---

func _ready() -> void:
    update_from_params(params)
    
func update_from_params(new_params: Dictionary = {}):
    if params == new_params:
        return
    
    # Update the main data object
    params = new_params
    
    ## Apply the new parameters
    set_setting_up_vars(true) # Set flag to not trigger bs
    
    # Identity
    creature_type = new_params.get("creature_type", creature_type)
    add_to_group(creature_type)
    name = new_params.get("name", creature_type.capitalize())
        
    # Flags:
    dead = new_params.get("dead", dead)
    is_frozen = new_params.get("is_frozen", is_frozen)
    allow_moving = new_params.get("allow_moving", allow_moving)
    
    # AI:
    _ai_info = new_params.get("ai_info", _ai_info)
    
    # Collision & Movement:
    _collision_info = new_params.get("collision_info", _collision_info)
    _movement_info = new_params.get("movement_info", _movement_info)
    
    # Blinking:
    _blinking_info = new_params.get("blinking_info", _blinking_info)
    
    # Additional Animation:
    var new_animation_info: Array[Dictionary] = new_params.get("animation_info", _animation_info)
    for i in range(new_animation_info.size()):
        var entry = new_animation_info[i]
        var player_name = entry.get("player", str(i) + "-Animator")
        var player_node = get_node(player_name)
        if is_instance_valid(player_node):
            anim_players[player_name] = player_node
            
    print(creature_type.capitalize() + " Anim_players: ", anim_players)
    
    # Optional Vars:
    if new_params.has("position"):
        _worldly_position = new_params.get("position", Vector2.ZERO)
    if new_params.has("grid_position"):
        var grid_pos = new_params.get("grid_position", Vector2.ZERO) 
        _worldly_position = grid_pos * Constants.tile_size
        
    # CreatureLogic
    update_logics(new_params)
        
    set_setting_up_vars(false) # Unset flag
    
func update_logics(new_params: Dictionary = {}):
    ## -- Health --
    var max_hp = new_params.get("max_hp", 100)
    var hp = new_params.get("hp", 100)
    
    if not is_instance_valid(_health_logic):
        _health_logic = CreatureHealth.new(hp, max_hp)
        
    _health_logic.died.connect(_on_died)
    _health_logic.health_updated.connect(_on_health_updated)
    
    ## -- Action --
    if not is_instance_valid(_action_logic):
        _action_logic = CreatureMover.new(self, _movement_info)
        
    _action_logic.action_finished.connect(_on_action_finished)
    
    ## -- AI --
    if not is_instance_valid(_ai_logic):
        _ai_logic = CreatureAI.new(self, _action_logic, _ai_info)
        
    _ai_logic.start_by_name() # Start behavior loop
    
    ## -- Blinking --
    var new_blinking_info = new_params.get("blinking_info", _blinking_info)
    
    if not is_instance_valid(_blinker_logic):
        _blinker_logic = CreatureBlinker.new(self, new_blinking_info)
    
    _blinker_logic.blink_end.connect(_on_blink_end)
    _blinker_logic.blink_start.connect(_on_blink_start)
    _blinker_logic.start_by_name() # Start Blinking
    
    ## -- Animation --
    var new_animation_info: Array[Dictionary] = new_params.get("animation_info", _animation_info)
    
    var keys = anim_players.keys()
    for i in range(keys.size()):
        var player_name: String = keys[i]
        var player_node: CreatureAnimator = anim_players.get(player_name, null)
        if is_instance_valid(player_node):
            player_node._animation_info = new_animation_info[i]
            player_node.play_by_name()
        
func get_logic_data() -> Dictionary:
    var logic_data: Dictionary = {
        "health_info": _health_info,
        "ai_info": _ai_info,
        "movement_info": _movement_info,
        "collision_info": _collision_info,
        "blinking_info": _blinking_info,
        "animation_info": _animation_info
    }
    return logic_data
    
## --- Public Custom Setter for Certain Values ---

func set_custom(prop_name: String, value: Variant):
    match(prop_name):
        "hp": _health_logic.set_hp(value)
        "max_hp": _health_logic.set_hp(_health_logic.get_hp(), value)
        _: self.set(prop_name, value)

## --- Child Parts & Saving ---

func get_child_parts(obj: Node = self) -> Array:
    var children = obj.get_children()
    var found_parts: Array = []
    for child in children:
        if child is BaseCreaturePart and child is not BaseCreatureEyelids and !child.procedurally_created:
            found_parts.append(child)
            var parts_of_part = get_child_parts(child)
            if parts_of_part:
                found_parts += parts_of_part
    return found_parts
    
func get_eyeish_children() -> Array:
    var children = get_children()
    var found_eyeish: Array = []
    for child in children:
        if child is BaseCreatureEye or child is BaseCreatureEyeContainer:
            found_eyeish.append(child)
    return found_eyeish
    
func get_body() -> BaseCreatureMainBody:
    var children = get_children()
    var body: BaseCreatureMainBody
    for child in children:
        if child is BaseCreatureMainBody and is_instance_valid(child):
            body = child
            break # Return the first that is found
            
    return body

    
func form_and_save_creature(desc: String = "Standard custom creature."):
    if Engine.is_editor_hint() or !self.is_node_ready():
        return
    
    var creature_data = SaveManager._formulate_creature_data(self, desc) 
    SaveManager.save_creature(creature_data, creature_type)

## --- Signal Handlers (The consequences of actions) ---
# -- Health --
func _on_died():
    dead = true # Update flag
    await collapse_scale()
    
    var effects = COLORED_RECTS.instantiate()
    effects.rect_col = get_body().body_color
    get_parent_world().add_child(effects)
    effects.z_index = self.z_index -1
    effects._worldly_position = _worldly_position
    
    if creature_type != "player": queue_free()
    
func _on_health_updated(current_hp, max_hp, _original_hp):
    # Update the visual HP bar
    handle_hp_bar(current_hp, max_hp)
    
# -- Blinker --

func _on_blink_start():
    pass

func _on_blink_end():
    pass
    
# -- Actions --
    
func _on_action_finished(_action_name: String):
    pass
    
## --- Public Methods ---
# -- Health --
func get_hp() -> float:
    return _health_logic.get_hp()
    
func get_max_hp() -> float:
    return _health_logic.get_max_hp()    

func hit(damage: float = 0.0):
    _health_logic.take_damage(damage) # Example damage
    
    if WorldUtils.is_in_player_world(self):
        return
        
    # Play hit sound/animation
    SoundManager.play_one_shot_2d(self, PLOP, 4.5, 0.4, 0.3)

# -- Blinker --

func blink():
    stop_blinking()
    await _blinker_logic.blink()
    
func stop_blinking():
    _blinker_logic.stop_blinking()
    
# -- Actions --

func move(dir: Vector2):
    _action_logic.move(dir)
    
func execute_action(action_name: String, parameters: Dictionary = {}, aftermove_delay: float = 0.0):
    _action_logic.execute_action(action_name, parameters, aftermove_delay)
    
## --- Utility ---
        
func check_pos_for_collision(dir: Vector2) -> bool:
    var hitbox_gridsize = _collision_info.get("hitbox_gridsize", Vector2.ONE)
    if hitbox_gridsize != Vector2.ONE:
        return check_rectangular_area_for_collision(dir, hitbox_gridsize)
    
    ## Update tile_map:
    var current_tile_map: Dictionary = WorldUtils.get_parent_world_tile_map(self)
    
    var check_pos: Vector2 = get_grid_pos() + dir
    var world_size = get_parent_world().world_size
    
    # World Boundary check
    if !WorldUtils.pos_is_inside_rect(check_pos, world_size):
        return true
            
    if current_tile_map.has(check_pos):    
        if not current_tile_map[check_pos]:
            return false
            
        if current_tile_map[check_pos] is Block:
            return true
        else: return false
    else:
        return false

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
    # If self.grid_pos is the center, this adjusts to the top-left.
    var half_body_x = floori(body_size_tiles.x / 2.0)
    var half_body_y = floori(body_size_tiles.y / 2.0)
    
    var current_top_left_grid_pos = get_grid_pos() - Vector2(half_body_x, half_body_y)
    
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

func is_able_to_move() -> bool:
    # This function will always check the CURRENT state of the variables.
    return (!dead and !is_frozen and allow_moving and !_setting_up_vars and _action_logic.no_action() and is_inside_tree())
    
func is_dead() -> bool:
    if dead: return true
    else:    return false
    
func get_grid_pos(pos_p: Vector2 = _worldly_position):
    var grid_pos = round(pos_p / Constants.tile_size)
    return grid_pos

func get_parent_world() -> World:
    var parent_world = WorldUtils.get_parent_world(self)
    return parent_world
    
func is_player_world() -> bool:
    var parent_world = WorldUtils.get_parent_world(self)
    if not is_instance_valid(parent_world):
        return false
        
    if parent_world.has_node("Player"):
        return true
    return false
    
func play_plop():
    if WorldUtils.is_in_player_world(self): ## Only play plop sounds if the player is also in this world     
        SoundManager.play_one_shot_2d(self, PLOP, 1.5, 0.4)
    
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
        
func set_setting_up_vars(value: bool = true):
    _setting_up_vars = value
        
func get_random_cardinal_dir() -> Vector2:
    match(randi_range(1, 4)):
        1: return Vector2.RIGHT
        2: return Vector2.LEFT
        3: return Vector2.DOWN
        4: return Vector2.UP
        _: return Vector2.RIGHT
        
func handle_hp_bar(hp: float, max_hp: float):
    if _setting_up_vars or not is_node_ready():
        return
    
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
