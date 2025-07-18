extends RefCounted

static func get_points(
    radius: float = 50 / sqrt(2),
    angle: float = 360.0,
    num_sides: int = 32,
    scale: Vector2 = Vector2.ONE,
    skew: float = 0.0,
    rotation_deg: float = 0.0,
    displacement: Vector2 = Vector2.ZERO
    ) -> PackedVector2Array:
        
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_circular_arc_points(radius, angle, num_sides)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_circular_arc_points(radius: float = 50 / sqrt(2), angle: float = 360.0, num_sides: int = 32) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    # Ensure sensible input
    if fmod(angle, 360) == 0:
        return _formulate_raw_circle_points(radius, num_sides)
    else: angle = fmod(angle, 360.0)
    
    # Logic
    var angle_step = TAU / num_sides
    if angle < 0.0:
        angle_step *= -1 # Inverse angle step if angle is negative
        
    for i in range(num_sides):
        var cumulative_angle = abs(rad_to_deg(angle_step * i))
        if cumulative_angle > abs(angle):
            break # No more points allowed
        shape_points.append(Vector2.RIGHT.rotated(i * angle_step) * radius)
    shape_points.append(Vector2.ZERO) # Point in center
    return shape_points
    
static func _formulate_raw_circle_points(radius: float = 50 / sqrt(2), num_sides: int = 32) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    var angle_step = TAU / num_sides    
    for i in range(num_sides):
        shape_points.append(Vector2.RIGHT.rotated(i * angle_step) * radius)
    return shape_points
