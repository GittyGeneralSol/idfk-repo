extends RefCounted
class_name CreatureMover

enum MoveType { SQUISH, SLIDE, FLOAT }

signal action_finished(action_name: String)

var _movement_info: Dictionary # Main Data Object
var _owner: Node2D # A reference to the BaseCreature node
var _current_action: String = ""

# The constructor takes the node it's supposed to control.
func _init(owner_node: Node2D, new_movement_info = {}):
    _owner = owner_node
    _movement_info = new_movement_info
    
func no_action() -> bool:
    if _current_action == "":
        return true
    return false
    
func get_current_action() -> String:
    return _current_action

# Public Method to do stuff according to Movement Info
func move(dir: Vector2):
    var aftermove_delay = _movement_info.get("aftermove_delay", 0.2)
    var move_time = _movement_info.get("move_time", 0.2)
    match(_movement_info.get("move_type")):
        MoveType.SQUISH: await execute_action("move_squish", { "direction": dir, "move_time": move_time }, aftermove_delay)
        MoveType.SLIDE: await execute_action("move_slide", { "direction": dir, "move_time": move_time }, aftermove_delay)
        _: await execute_action("move_squish", { "direction": dir, "move_time": move_time }, aftermove_delay)

# This is a public method to do any premade move.
func execute_action(action_name: String, parameters: Dictionary = {}, aftermove_delay: float = 0.0):
    if _current_action != "" or not is_instance_valid(_owner):
        return

    _current_action = action_name
    
    match(action_name):
        "move_squish":
            # Check for collision using the owner's context
            var dir = parameters.get("direction", Vector2.RIGHT)
            var time_to_move = parameters.get("move_time", 0.2)
            
            if _owner.check_pos_for_collision(dir):
                await _animate_bump(dir, time_to_move)
            else:
                await move_squish_st(dir, time_to_move)
                
        "move_slide":
            var dir = parameters.get("direction", Vector2.RIGHT)
            var time_to_move = parameters.get("move_time", 0.2)
            
            if _owner.check_pos_for_collision(dir):
                await _animate_bump(dir, time_to_move)
            else:
                await move_regular_st(dir, time_to_move)
            
        "idle":
            var idle_time = parameters.get("idle_time", 8.0)
            await idle(idle_time)
            
    ## Aftermove Delay
    if aftermove_delay > 0:
        await _owner.get_tree().create_timer(aftermove_delay).timeout

    _current_action = ""
    emit_signal("action_finished", action_name) # FIX: Signal name was "move_finished"

#region --- Individual Actions ---

func move_squish_st(dir: Vector2, time_to_move: float = 0.2):
    ## Get squishing info from the owner
    var move_x_factor = _movement_info.get("x_squish_factor", 1.25)
    var move_y_factor = _movement_info.get("y_squish_factor", 1.25)
    
    ## Initialize vars
    var target_pos: Vector2
    var move_squish: Vector2 = Vector2.ONE
    var eye_target_pos: Vector2

    ## Direction Handling:
    var move_step = _movement_info.get("move_step", Constants.tile_size)
    ## Access worldly_position through the owner
    target_pos = _owner._worldly_position + dir * move_step
    eye_target_pos = dir * _movement_info.get("eye_movement", 7)
    
    if dir.x != 0: # Horizontal move
        move_squish = Vector2(1.0 * move_x_factor, 1.0 / move_x_factor)
    elif dir.y != 0: # Vertical move
        move_squish = Vector2(1.0 / move_y_factor, 1.0 * move_y_factor)
    
    ## Calibrate Target Position
    target_pos.x = snapped(target_pos.x, move_step)
    target_pos.y = snapped(target_pos.y, move_step)
    
    ## Get parent world through the owner
    var world_size_p = _owner.get_parent_world().world_size_p
    target_pos.x = clamp(target_pos.x, -world_size_p.x/2, world_size_p.x/2)
    target_pos.y = clamp(target_pos.y, -world_size_p.y/2, world_size_p.y/2)
    
    ## --- Movement ---
    _owner.play_plop()
    
    ## Animation:
    await move_squish_animation(target_pos, eye_target_pos, time_to_move, move_squish)
        
func move_regular_st(dir: Vector2, time_to_move: float = 0.2):
    ## At the start of any move, create a lock.
    _current_action = "move_slide"
    
    ## Initialize vars
    var target_pos: Vector2 = Vector2.ZERO
    var eye_target_pos: Vector2 = Vector2.ZERO
    
    ## Direction Handling:
    var move_step = _movement_info.get("move_step", Constants.tile_size)
    target_pos = _owner._worldly_position + dir * move_step
    eye_target_pos = dir * _movement_info.get("eye_movement", 7)
    
    ## Calibrate Target Position
    target_pos.x = snapped(target_pos.x, move_step)
    target_pos.y = snapped(target_pos.y, move_step)
    
    ## Get parent world through the owner
    var world_size_p = _owner.get_parent_world().world_size_p
    target_pos.x = clamp(target_pos.x, -world_size_p.x/2, world_size_p.x/2)
    target_pos.y = clamp(target_pos.y, -world_size_p.y/2, world_size_p.y/2)
            
    ## Animation:
    await move_slide_animation(target_pos, eye_target_pos, time_to_move)
    
func idle(idle_time: float = 8.0):
    if idle_time <= 4.0:
        if is_instance_valid(_owner):
            await _owner.get_tree().create_timer(idle_time).timeout
        return
    
    # --- Move to Center ---
    await move_eyes_animation(Vector2.ZERO, 0.1)
    
    # Access name property from owner
    print(_owner.name, ": Idling!")

    # --- First Eye Move ---
    # Call helper function on owner, get data from owner
    var target_pos = _owner.get_random_cardinal_dir() * _owner.movement_info.get("eye_movement", 7)
    await move_eyes_animation(target_pos, 0.1)
    
    # --- Delay ---
    await _owner.get_tree().create_timer(idle_time / 2.0).timeout
    
    # --- Second Eye Move ---
    target_pos = _owner.get_random_cardinal_dir() * _owner.movement_info.get("eye_movement", 7)
    await move_eyes_animation(target_pos, 0.1)

    # --- Final Delay ---
    await _owner.get_tree().create_timer(idle_time / 2.0).timeout
    print(_owner.name, ": Idle complete!")

#endregion

#region --- Animations ---

func move_eyes_animation(target_pos: Vector2, time_to_move: float = 0.1):
    if is_instance_valid(_owner._current_eyeish_tween):
        _owner._current_eyeish_tween.kill()
        
    _owner._current_eyeish_tween = _owner.create_tween()
    
    ## Call helper on owner
    for eyeish_node in _owner.get_eyeish_children():
        _owner._current_eyeish_tween.parallel().tween_property(eyeish_node, "position", target_pos, time_to_move)
    
    await _owner._current_eyeish_tween.finished

func move_squish_animation(target_pos: Vector2, eye_target_pos: Vector2, time_to_move: float, move_scaling: Vector2):
    if is_instance_valid(_owner._current_move_tween):
        _owner._current_move_tween.kill()

    var scale_tween = _owner.create_tween()
    _owner._current_move_tween = _owner.create_tween()
    
    _owner._current_move_tween.tween_property(_owner, "_worldly_position", target_pos, time_to_move)
    
    scale_tween.tween_property(_owner, "scale", move_scaling, time_to_move / 2.0)
    scale_tween.tween_property(_owner, "scale", Vector2.ONE, time_to_move / 2.0)
    move_eyes_animation(eye_target_pos, 0.1)
    
    await _owner._current_move_tween.finished
    
func move_slide_animation(target_pos: Vector2, eye_target_pos: Vector2, time_to_move: float):
    # Manage tween
    if is_instance_valid(_owner._current_move_tween):
        _owner._current_move_tween.kill()
        
    _owner._current_move_tween = _owner.create_tween()
    
    # Move
    _owner._current_move_tween.tween_property(_owner, "_worldly_position", target_pos, time_to_move)
    move_eyes_animation(eye_target_pos, 0.1)
    
    await _owner._current_move_tween.finished
    
func _animate_bump(direction: Vector2, time_to_move: float):
    if not is_instance_valid(_owner) or _owner.dead:
        return
    
    ## Get collision info from owner
    var col_info = _owner.collision_info
    
    var primary_movement: Vector4 = col_info.get("primary_movement", Vector4(20, 20, 20, 20))
    var _secondary_movement: Vector4 = col_info.get("secondary_movement", Vector4(10, 10, 10, 10))
    var x_factor = col_info.get("x_squish_factor", 1.25)
    var y_factor = col_info.get("y_squish_factor", 1.25)
    
    var primary_dist_to_move: float
    var squish_vector: Vector2
    
    match(direction):
        Vector2.UP:
            primary_dist_to_move = primary_movement.x
            squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.DOWN:
            primary_dist_to_move = primary_movement.y
            squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.LEFT:
            primary_dist_to_move = primary_movement.z
            squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
        Vector2.RIGHT:
            primary_dist_to_move = primary_movement.w
            squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
  
    ## 1. Animate CREATURE moving towards wall
    var original_pos: Vector2 = _owner._worldly_position
    var bump_target_pos = original_pos + direction * primary_dist_to_move
    
    var bump_tween = _owner.create_tween()
    bump_tween.set_parallel()
    bump_tween.tween_property(_owner, "_worldly_position", bump_target_pos, time_to_move / 2.0)
    bump_tween.tween_property(_owner, "scale", squish_vector, time_to_move / 2.0)
    
    # Hold the bump
    await bump_tween.finished
    
    # Return to original state
    var return_tween = _owner.create_tween()
    return_tween.set_parallel()
    return_tween.tween_property(_owner, "_worldly_position", original_pos, time_to_move / 2.0)
    return_tween.tween_property(_owner, "scale", Vector2.ONE, time_to_move / 2.0)

    await return_tween.finished

#endregion
