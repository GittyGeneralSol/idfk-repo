extends RefCounted

enum GenerationType { EQUILATERAL_FROM_SIDE, EQUILATERAL_FROM_CIRCUMRADIUS, RIGHT_FROM_LEGS, ISOSCELES }

static func get_points(
    triangle_info: Dictionary,
    scale: Vector2 = Vector2.ONE,
    skew: float = 0.0,
    rotation_deg: float = 0.0,
    displacement: Vector2 = Vector2.ZERO
    ) -> PackedVector2Array:
        
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_triangle_points(triangle_info)
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_triangle_points(triangle_info: Dictionary) -> PackedVector2Array:
    var gen_type: GenerationType = triangle_info.get("gen_type", GenerationType.EQUILATERAL_FROM_SIDE)
    
    match(gen_type):
        GenerationType.EQUILATERAL_FROM_SIDE:
            var side_length: float = triangle_info.get("side_length", 100.0)
            return _generate_equilateral_from_side(side_length)
            
        GenerationType.EQUILATERAL_FROM_CIRCUMRADIUS:
            var radius: float = triangle_info.get("radius", 50.0)
            return _generate_equilateral_from_radius(radius)
            
        GenerationType.RIGHT_FROM_LEGS:
            var size: Vector2 = triangle_info.get("size", Vector2(50, 50))
            return _generate_right(size)
            
        GenerationType.ISOSCELES:
            var size: Vector2 = triangle_info.get("size", Vector2(50, 50))
            return _generate_isosceles(size)
            
    return []

static func _generate_equilateral_from_side(side: float) -> PackedVector2Array:
    var height = (sqrt(3.0) / 2.0) * side
    
    var p1 = Vector2(-side / 2.0, height / 2.0)
    var p2 = Vector2(side / 2.0, height / 2.0)
    var p3 = Vector2(0, -height / 2.0)
    
    return [p1, p2, p3]

static func _generate_equilateral_from_radius(radius: float) -> PackedVector2Array:
    var points: PackedVector2Array
    var angle_step = TAU / 3.0
    
    for i in range(3):
        points.append(Vector2.UP.rotated(i * angle_step) * radius)
        
    return points

static func _generate_right(size: Vector2) -> PackedVector2Array:
    var p1 = Vector2(0, 0)
    var p2 = Vector2(size.x, 0)
    var p3 = Vector2(0, -size.y)
    
    var centroid = (p1 + p2 + p3) / 3.0
    return [p1 - centroid, p2 - centroid, p3 - centroid]

static func _generate_isosceles(size: Vector2) -> PackedVector2Array:
    var p1 = Vector2(-size.x / 2.0, size.y / 2.0)
    var p2 = Vector2(size.x / 2.0, size.y / 2.0)
    var p3 = Vector2(0, -size.y / 2.0)
    
    return [p1, p2, p3]
