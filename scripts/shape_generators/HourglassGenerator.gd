extends RefCounted

static func get_points(
    width: float = 200,
    height: float = 240,
    notch_width: float = 50.0,
    bottom_displ := Vector2.ZERO,
    top_displ := Vector2.ZERO,
    scale: Vector2 = Vector2.ONE,
    skew: float = 0.0,
    rotation_deg: float = 0.0,
    displacement: Vector2 = Vector2.ZERO
    ) -> PackedVector2Array:
        
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_hourglass_points(width, height, notch_width, bottom_displ, top_displ)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_hourglass_points(width: float = 200, height: float = 240, notch_width: float = 50.0, bottom_displ := Vector2.ZERO, top_displ := Vector2.ZERO) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    var half_w = width/2
    var half_notch_w = notch_width/2
    var half_h = height/2
    
    shape_points.append(Vector2(-half_w, half_h) + bottom_displ) # Bottom-left
    shape_points.append(Vector2(half_w, half_h) + bottom_displ) # Bottom-right
    shape_points.append(Vector2(half_notch_w, 0.0)) # Middle-right
    shape_points.append(Vector2(half_w, -half_h) + top_displ) # Top-right
    shape_points.append(Vector2(-half_w, -half_h) + top_displ) # Top-left
    shape_points.append(Vector2(-half_notch_w, 0.0)) # Middle-left
    
    return shape_points
