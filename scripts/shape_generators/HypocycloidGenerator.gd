extends RefCounted

# Generates the points for an n-cusped hypocycloid (n-cuspoid)
static func generate_hypocycloid_points(n: int, R: float, count: int, offset: Vector2, rotation_deg: float = 0.0) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array()
    if count < 4:
        count = 4 # Minimum points

    # Calculate the radius of the inner rolling circle
    var r = R / float(n)
    if is_zero_approx(r):
        # Avoid division by zero if R is 0 or n is huge/invalid
        return points

    var angle_step_rad = deg_to_rad(360.0 / count) # Step in radians

    # Use the general parametric equation for hypocycloids
    # x(t) = (R - r) * cos(t) + r * cos((R / r - 1) * t)
    # y(t) = (R - r) * sin(t) - r * sin((R / r - 1) * t)
    # Substitute R/r = n
    # x(t) = (R - R/n) * cos(t) + R/n * cos((n - 1) * t)
    # y(t) = (R - R/n) * sin(t) - R/n * sin((n - 1) * t)

    var R_minus_r = R - r # (n-1)r
    
    # Convert rotation_deg to rotation_rad:
    var rotation_rad = deg_to_rad(rotation_deg)

    for i in range(count):
        var angle_rad = i * angle_step_rad # Parameter t

        var x = R_minus_r * cos(angle_rad) + r * cos((n - 1.0) * angle_rad)
        var y = R_minus_r * sin(angle_rad) - r * sin((n - 1.0) * angle_rad)
        var point = Vector2(x, y)
        
        # Rotate the point before adding offset
        var rotated_point = point.rotated(rotation_rad)
        
        # Add the point to the array, applying the offset
        points.append(rotated_point + offset)

    return points
