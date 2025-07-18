extends RefCounted
    
func formulate_triangle_points(size: int, v_displ: int, h_displ: int, final_displ: Vector2, upside_dwn: bool = false, angle: float = 0.0, final_rot_deg: float = 0.0)  -> PackedVector2Array:
     
    if (upside_dwn == false):
        ## Defining the points:
        var p1 = Vector2(-size, size)
        var p2 = Vector2(0, -size)
        var p3 = Vector2(size, size)
        
        ## Rotating the points:
        
        var rotation_rad = deg_to_rad(angle)
        
        p1 = p1.rotated(rotation_rad)
        p2 = p2.rotated(rotation_rad)
        p3 = p3.rotated(rotation_rad)
        
        ## Horizontally && Vertically Displacing the Points:
        
        p1 = p1 + Vector2(h_displ, -v_displ)
        p2 = p2 + Vector2(h_displ, -v_displ)
        p3 = p3 + Vector2(h_displ, -v_displ)
        
        ## Displacing the points one final time:
        var final_p1 = p1 + final_displ
        var final_p2 = p2 + final_displ
        var final_p3 = p3 + final_displ
        
        ## Rotating the points AFTER displacement:
        
        var final_rot_rad = deg_to_rad(final_rot_deg)
        
        final_p1 = final_p1.rotated(final_rot_rad)
        final_p2 = final_p2.rotated(final_rot_rad)
        final_p3 = final_p3.rotated(final_rot_rad)
        
        ## Packing Points:
        var triangle_points = PackedVector2Array([final_p1, final_p2, final_p3])
        
        ## Returning the Triangle Points to caller:
        return(triangle_points)
        
    else:
        ## Defining the points:
        var p1 = Vector2(-size, -size)
        var p2 = Vector2(0, size)
        var p3 = Vector2(size, -size)
        
        ## Rotating the points:
        
        var rotation_rad = deg_to_rad(angle)
        
        p1 = p1.rotated(rotation_rad)
        p2 = p2.rotated(rotation_rad)
        p3 = p3.rotated(rotation_rad)
        
        ## Horizontally && Vertically Displacing the Points:
        
        p1 = p1 + Vector2(h_displ, +v_displ)
        p2 = p2 + Vector2(h_displ, +v_displ)
        p3 = p3 + Vector2(h_displ, +v_displ)
        
        ## Displacing the points one final time:
        var final_p1 = p1 + final_displ
        var final_p2 = p2 + final_displ
        var final_p3 = p3 + final_displ
        
        ## Rotating the points AFTER displacement:
        
        var final_rot_rad = deg_to_rad(final_rot_deg)
        
        final_p1 = final_p1.rotated(final_rot_rad)
        final_p2 = final_p2.rotated(final_rot_rad)
        final_p3 = final_p3.rotated(final_rot_rad)
        
        ## Packing Points:
        var triangle_points = PackedVector2Array([final_p1, final_p2, final_p3])
        
        ## Returning the Triangle Points to caller:
        return(triangle_points)

# Default to using size as distance from center
func get_equilateral_triangle_points(size: float, size_type: String = "center_distance", rotation_angle_degrees: float = 0.0, displacement: Vector2 = Vector2.ZERO) -> PackedVector2Array:

    var R: float # This will be the Circumradius (distance from center to vertices)

    # Calculate the Circumradius (R) based on the provided size and type
    match size_type:
        "center_distance":
            R = size # The input size is already the distance from center to vertex
        "height":
            # The height (h) of an equilateral triangle is h = 3R/2
            # So, R = 2h/3
            R = size * 2.0 / 3.0
        "base":
            # The base (b) of an equilateral triangle is b = R * sqrt(3)
            # So, R = b / sqrt(3)
            # Need to use 3.0 for float division
            R = size / sqrt(3.0)
        _:
            # Handle unexpected size_type (shouldn't happen if using the enum)
            push_error("Invalid size_type for get_equilateral_triangle_points.")
            R = size # Default to center distance in case of error

    # Define the angles for the three vertices of an equilateral triangle
    # centered at (0,0) with one vertex pointing upwards along the y-axis initially.
    # The angles are relative to the positive x-axis (0 degrees/radians).
    # Vertex 1 (Top): Angle = 90 degrees (PI/2 radians) -> (0, R)
    # Vertex 2 (Bottom-Left): Angle = 90 + 120 = 210 degrees (PI/2 + 2*PI/3 = 7*PI/6 radians)
    # Vertex 3 (Bottom-Right): Angle = 90 - 120 = -30 degrees (PI/2 - 2*PI/3 = -PI/6 radians)
    # Using PI/2, 7*PI/6, and -PI/6 radians for simplicity.

    var base_angles_rad = PackedFloat32Array([PI/2.0, 7.0*PI/6.0, -PI/6.0])

    var points = PackedVector2Array()
    var rotation_rad = deg_to_rad(rotation_angle_degrees)

    # Calculate the position of each vertex and apply the rotation
    for angle in base_angles_rad:
        # Calculate the base position of the vertex on a circle of radius R
        # This is the vertex position *before* applying the user's rotation_angle
        var base_pos = Vector2(R * cos(angle), R * sin(angle))

        # Apply the desired rotation to the base position
        var rotated_pos = base_pos.rotated(rotation_rad)
        
        # Add final displacement to point:
        var final_pos = rotated_pos + displacement

        # Add the final rotated, displaced point to our list
        points.push_back(final_pos)

    # Return the list of the three calculated vertex points
    return points
