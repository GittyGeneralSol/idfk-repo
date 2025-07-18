extends RefCounted

static func get_points(
    width: float = 120,
    height: float = 240,
    bottom_displ := Vector2.ZERO,
    top_displ := Vector2.ZERO,
    scale: Vector2 = Vector2.ONE,
    skew: float = 0.0,
    rotation_deg: float = 0.0,
    displacement: Vector2 = Vector2.ZERO
    ) -> PackedVector2Array:
        
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_diamond_points(width, height, bottom_displ, top_displ)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_diamond_points(width: float = 120, height: float = 240, bottom_displ := Vector2.ZERO, top_displ := Vector2.ZERO) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    var half_w = width/2
    var half_h = height/2
    
    shape_points.append(Vector2(0, half_h) + bottom_displ) # Bottom
    shape_points.append(Vector2(half_w, 0)) # Middle-right
    shape_points.append(Vector2(0, -half_h) + top_displ) # Top
    shape_points.append(Vector2(-half_w, 0)) # Middle-right
    
    return shape_points
