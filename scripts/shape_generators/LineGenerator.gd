extends RefCounted

static func get_points(length: float = 200, width: float = 10, scale: Vector2 = Vector2.ONE, skew: float = 0.0, rotation_deg: float = 0.0, displacement: Vector2 = Vector2.ZERO) -> PackedVector2Array:
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_line_points(length, width)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_line_points(length: float = 200, width: float = 240) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    var half = Vector2(length, width) / 2.0
    shape_points.append(Vector2(-half.x, -half.y))
    shape_points.append(Vector2( half.x, -half.y))
    shape_points.append(Vector2( half.x,  half.y))
    shape_points.append(Vector2(-half.x,  half.y))
    
    return shape_points
