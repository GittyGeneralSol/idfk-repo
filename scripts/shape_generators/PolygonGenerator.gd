extends RefCounted

static func generate_polygon_points(num_sides: int = 5, circumrad: float = 10, displacement: Vector2 = Vector2.ZERO, rotation_deg: float = 0.0, snap_closest: bool = false) -> PackedVector2Array:
    var points: PackedVector2Array = ([])
    if num_sides < 3:
        return points
        
    # Convert rotation_deg to rotation_rad:
    var rotation_rad = deg_to_rad(rotation_deg)
    
    ## Numb. of points = number of sides
    var num_points = num_sides
    
    for point_num in num_points:
        var current_point_angle = 360/num_points * point_num
        var angle_rad = deg_to_rad(current_point_angle)
        
        # Use parametric equations of circles to find the point:
        var x = circumrad * cos(angle_rad) if snap_closest == false else round(circumrad * cos(angle_rad))
        var y = circumrad * sin(angle_rad) if snap_closest == false else round(circumrad * sin(angle_rad))
        var point = Vector2(x, y)
        
        # Rotate the point:
        point = point.rotated(rotation_rad)
        
        # Displace the point:
        point += displacement
        
        # Rounding if required:
        if snap_closest:
            point.x = round(point.x)
            point.y = round(point.y)
        
        points.append(point) # Add to array
    
    return points

static func generate_reuleaux_polygon_points(num_sides: int = 5, desired_circumrad: float = 10, displacement: Vector2 = Vector2.ZERO, rotation_deg: float = 0.0) -> PackedVector2Array:
    var points: PackedVector2Array = ([])
    if num_sides < 3:
        return points
        
    # Convert rotation_deg to rotation_rad:
    var rotation_rad = deg_to_rad(rotation_deg)
    
    ## Here, numb. of points is NOT equal to numb of sides.
    var num_of_points = 360 # one for each degree
    
    for point_num in num_of_points:
        var current_point_angle = 360/num_of_points * point_num
        var angle_rad = deg_to_rad(current_point_angle)
        
        # Use parametric equations to find the point:
        var n = num_sides # NOT numb of points. 
        var t = angle_rad
        var A = (PI / float(n)) * (2.0 * floor((float(n) * t) / (2.0 * PI)) + 1.0)
        var x = 2.0 * cos(PI / (2.0 * float(n))) * cos(0.5 * (t + A)) - cos(A)
        var y = 2.0 * cos(PI / (2.0 * float(n))) * sin(0.5 * (t + A)) - sin(A)
        
        var point = Vector2(x, y)
        
        ## Properly scaling the magnitude of the current point to given circumrad:
        
        point *= desired_circumrad
        
        # Rotate the point:
        point = point.rotated(rotation_rad)
        
        # Displace the point:
        point += displacement
        
        points.append(point) # Add to array
    
    return points
