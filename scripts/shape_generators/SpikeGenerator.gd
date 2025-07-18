extends RefCounted

static func get_points(
    base_width: float = 120,
    base_height: float = 40,
    spike_height: float = 200,
    bottom_displ := Vector2.ZERO,
    top_displ := Vector2.ZERO,
    scale: Vector2 = Vector2.ONE,
    skew: float = 0.0,
    rotation_deg: float = 0.0,
    displacement: Vector2 = Vector2.ZERO
    ) -> PackedVector2Array:
        
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_hourglass_points(base_width, base_height, spike_height, bottom_displ, top_displ)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_hourglass_points(base_width: float = 120, base_height: float = 40, spike_height: float = 200, bottom_displ := Vector2.ZERO, top_displ := Vector2.ZERO) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    var total_height = base_height + spike_height
    var half_toth = total_height/2
    var half_bw = base_width/2
    var middle_y = half_toth - base_height
    
    shape_points.append(Vector2(-half_bw, half_toth) + bottom_displ) # Bottom-left
    shape_points.append(Vector2(half_bw, half_toth) + bottom_displ) # Bottom-right
    shape_points.append(Vector2(half_bw, middle_y)) # Middle-right
    shape_points.append(Vector2(0, -half_toth) + top_displ) # Top
    shape_points.append(Vector2(-half_bw, middle_y)) # Middle-left
    
    return shape_points
