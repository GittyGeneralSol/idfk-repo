extends RefCounted

## Here, center_position == displacement
static func get_star_points(num_points: int = 5,
     outer_radius: float = 25.0,
     inner_radius: float = 15.0,
     center_position: Vector2 = Vector2.ZERO,
     rotation_deg: float = 0.0) -> PackedVector2Array:
    
    var points: PackedVector2Array = ([])
    
    # Ensure a valid number of points (at least three for a star shape):
    if num_points < 3: push_error("Star must have at least three points."); return points
    
    var total_vertices = num_points * 2
    var angle_step = deg_to_rad(360 / total_vertices)
    var initial_angle_rad = deg_to_rad(rotation_deg)
    
    for i in range(total_vertices):
        var current_radius: float
        var current_angle: float = initial_angle_rad + i * angle_step # Initially zero
        
        # Determine if it is an outer vertex (even index) or inner vertex (odd index)
        if(i % 2 == 0): current_radius = outer_radius
        else: current_radius = inner_radius
        
        # Calculate the vertex position relative to (0, 0):
        var vertex_pos_relative = Vector2(current_radius * cos(current_angle), current_radius * sin(current_angle))
        
        # Add the center position to get the final vertex position:
        var vertex_pos_final = Vector2(current_radius * cos(current_angle), current_radius * sin(current_angle)) + center_position
        
        points.append(vertex_pos_final)
        
    return points
