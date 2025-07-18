extends Node2D

static func block_collision(object: BaseCreature, direction: Vector2, time_to_move: float, eye_target_pos: Vector2): # Renamed scale arg
    if not object:
        return
    
    var col_info = object.get("collision_info")
    if object.dead or not col_info:
        return
    
    # Get the distances to the next tile over
    var dist_to_bounds = col_info.get("dist_to_bounds")
    var x_factor = col_info.get("x_squish_factor", 1.25)
    var y_factor = col_info.get("y_squish_factor", 1.25)
    
    var dist_to_move: float
    var squish_vector: Vector2
    match(direction):
        Vector2.UP:    dist_to_move = dist_to_bounds.get("up");    squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.DOWN:  dist_to_move = dist_to_bounds.get("down");  squish_vector = Vector2(1.0 * y_factor, 1.0 / y_factor)
        Vector2.LEFT:  dist_to_move = dist_to_bounds.get("left");  squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
        Vector2.RIGHT: dist_to_move = dist_to_bounds.get("right"); squish_vector = Vector2(1.0 / x_factor, 1.0 * x_factor)
    print("OBJ: ", object, ": squish_scale_vector: ", squish_vector)

    ## 1. Animate CREATURE moving towards wall
    # Calculate target pos
    var original_pos: Vector2 = object._worldly_position # Use _worldly_position for the bump
    var max_displ = direction * dist_to_move
    var target_pos = original_pos + max_displ
    
    var move_to_wall_tween = object.create_tween()
    move_to_wall_tween.tween_property(object, "_worldly_position", target_pos, time_to_move/2.0)
    await move_to_wall_tween.finished
    if not object: return
    
    ## 2. Animate CREATURE scaling plus creature moving forward INTO the wall
    # Calculate target pos
    var next_to_wall_pos: Vector2 = object._worldly_position
    max_displ = direction * dist_to_move * min(squish_vector.x, squish_vector.y) / 2
    target_pos = next_to_wall_pos + max_displ
    
    var collision_tween = object.create_tween()
    collision_tween.tween_property(object, "scale", squish_vector, time_to_move/2.0)
    collision_tween.parallel().tween_property(object, "_worldly_position", target_pos, time_to_move/2.0)
    
    ## 3. Add a short delay (hold the bump/squish)
    collision_tween.tween_interval(0.2)

    ## 4. Animate CREATURE's scale normalizing and creature going back to being against the wall and not in
    collision_tween.tween_property(object, "scale", Vector2(1, 1), time_to_move/2.0)
    collision_tween.parallel().tween_property(object, "_worldly_position", next_to_wall_pos, time_to_move/2.0)
    await collision_tween.finished
    if not object: return
    
    # Hold..
    #await object.get_tree().create_timer(0.2).timeout
    #if not object: return
    
    ## 5. Animate CREATURE moving AWAY FROM wall
    # Calculate target pos
    var move_away_from_wall_tween = object.create_tween()
    move_away_from_wall_tween.tween_property(object, "_worldly_position", original_pos, time_to_move/2.0)
    await move_away_from_wall_tween.finished
