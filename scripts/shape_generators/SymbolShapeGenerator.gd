extends RefCounted

const symbol_data: Dictionary = {
    "a": [Vector2(-120.0, 120.0), Vector2(-60.0, 120.0), Vector2(-33.0, 40.0), Vector2(33.0, 40.0), Vector2(60.0, 120.0), Vector2(120.0, 120.0), Vector2(36.0, -120.0), Vector2(-36.0, -120.0)],
    "b_sharp": [Vector2(-63.0, 120.0), Vector2(40.0, 120.0), Vector2(100.0, 60.0), Vector2(40.0, 0.0), Vector2(100.0, -60.0), Vector2(40.0, -120.0), Vector2(-63.0, -120.0)],
    "x": [Vector2(-120.0, 120.0), Vector2(-60.0, 120.0), Vector2(0.0, 40.0), Vector2(60.0, 120.0), Vector2(120.0, 120.0), Vector2(30.0, 0.0), Vector2(120.0, -120.0), Vector2(60.0, -120.0), Vector2(0.0, -40.0), Vector2(-60.0, -120.0), Vector2(-120.0, -120.0), Vector2(-30.0, 0.0)],
    "x_thin": [Vector2(-120.0, 120.0), Vector2(-80.0, 120.0), Vector2(0.0, 25.0), Vector2(80.0, 120.0), Vector2(120.0, 120.0), Vector2(25.0, 0.0), Vector2(120.0, -120.0), Vector2(80.0, -120.0), Vector2(0.0, -25.0), Vector2(-80.0, -120.0), Vector2(-120.0, -120.0), Vector2(-25.0, 0.0)],
    "hourglass": [Vector2(-100.0, 120.0), Vector2(100.0, 120.0), Vector2(25.0, 0.0), Vector2(100.0, -120.0), Vector2(-100.0, -120.0), Vector2(-25.0, 0.0)],
    "hourglass_thin": [Vector2(-100.0, 150.0), Vector2(100.0, 150.0), Vector2(5.0, 0.0), Vector2(100.0, -150.0), Vector2(-100.0, -150.0), Vector2(-5.0, 0.0)],
    "k":  [Vector2(-80.0, 120.0), Vector2(-20.0, 120.0), Vector2(-20.0, 59.0), Vector2(0.0, 28.0), Vector2(44.0, 120.0), Vector2(106.0, 120.0), Vector2(30.0, -19.0), Vector2(94.0, -120.0), Vector2(35.0, -120.0), Vector2(-20.0, -32.0), Vector2(-20.0, -120.0), Vector2(-80.0, -120.0)],
    "k_filled": [Vector2(-90.0, 120.0), Vector2(90.0, 120.0), Vector2(15.0, 0.0), Vector2(90.0, -120.0), Vector2(-90.0, -120.0)],
    "k_filled_jagged": [Vector2(-80.0, 120.0), Vector2(106.0, 120.0), Vector2(30.0, -19.0), Vector2(94.0, -120.0), Vector2(-80.0, -120.0)],
    "diamond": [Vector2(0.0, 120.0), Vector2(60.0, 0.0), Vector2(0.0, -120.0), Vector2(-60.0, 0.0)],
    "spike": [Vector2(-60.0, 120.0), Vector2(60.0, 120.0), Vector2(60.0, 80.0), Vector2(0.0, -120.0), Vector2(-60.0, 80.0)],
    "plumbbob": [Vector2(20.0, -29.10339), Vector2(25.0, -25.00001), Vector2(29.39689, -19.64238), Vector2(32.66408, -13.5299), Vector2(34.676, -6.897484), Vector2(35.35534, 0.0), Vector2(34.67599, 6.897484), Vector2(32.66408, 13.52991), Vector2(29.39689, 19.64237), Vector2(25.0, 25.0), Vector2(19.64237, 29.39689), Vector2(13.5299, 32.66408), Vector2(6.897484, 34.67599), Vector2(0.0, 35.35534), Vector2(-6.897484, 34.67599), Vector2(-13.5299, 32.66408), Vector2(-19.64237, 29.39689), Vector2(-25.0, 25.0), Vector2(-29.39689, 19.64237), Vector2(-32.66408, 13.52991), Vector2(-34.676, 6.897484), Vector2(-35.35534, 0.0), Vector2(-34.676, -6.897484), Vector2(-32.66408, -13.5299), Vector2(-29.39689, -19.64238), Vector2(-25.0, -25.0), Vector2(-20.0, -29.10339), Vector2(-20.0, -100.0), Vector2(20.0, -100.0)],
    "circle_pointy": [Vector2(12.58512, -32.95066), Vector2(13.52991, -32.66407), Vector2(19.64237, -29.3969), Vector2(25.0, -25.00001), Vector2(29.39689, -19.64238), Vector2(32.66408, -13.5299), Vector2(34.676, -6.897484), Vector2(35.35534, 0.0), Vector2(34.67599, 6.897484), Vector2(32.66408, 13.52991), Vector2(29.39689, 19.64237), Vector2(25.0, 25.0), Vector2(19.64237, 29.39689), Vector2(13.5299, 32.66408), Vector2(6.897484, 34.67599), Vector2(0.0, 35.35534), Vector2(-6.897484, 34.67599), Vector2(-13.5299, 32.66408), Vector2(-19.64237, 29.39689), Vector2(-25.0, 25.0), Vector2(-29.39689, 19.64237), Vector2(-32.66408, 13.52991), Vector2(-34.676, 6.897484), Vector2(-35.35534, 0.0), Vector2(-34.676, -6.897484), Vector2(-32.66408, -13.5299), Vector2(-29.39689, -19.64238), Vector2(-25.0, -25.0), Vector2(-19.64238, -29.39689), Vector2(-13.52991, -32.66408), Vector2(-12.58511, -32.95067), Vector2(0.0, -54.74874)],
    "circle_pointy_2": [Vector2(12.58512, -32.95066), Vector2(13.52991, -32.66407), Vector2(19.64237, -29.3969), Vector2(25.0, -25.00001), Vector2(29.39689, -19.64238), Vector2(32.66408, -13.5299), Vector2(34.676, -6.897484), Vector2(35.35534, 0.0), Vector2(34.67599, 6.897484), Vector2(32.66408, 13.52991), Vector2(29.39689, 19.64237), Vector2(25.0, 25.0), Vector2(19.64237, 29.39689), Vector2(13.5299, 32.66408), Vector2(12.58511, 32.95067), Vector2(0.0, 54.74874), Vector2(-12.58511, 32.95067), Vector2(-13.5299, 32.66408), Vector2(-19.64237, 29.39689), Vector2(-25.0, 25.0), Vector2(-29.39689, 19.64237), Vector2(-32.66408, 13.52991), Vector2(-34.676, 6.897484), Vector2(-35.35534, 0.0), Vector2(-34.676, -6.897484), Vector2(-32.66408, -13.5299), Vector2(-29.39689, -19.64238), Vector2(-25.0, -25.0), Vector2(-19.64238, -29.39689), Vector2(-13.52991, -32.66408), Vector2(-12.58511, -32.95067), Vector2(0.0, -54.74874)],
    "circle_pointy_3": [Vector2(12.58512, -32.95066), Vector2(13.52991, -32.66407), Vector2(19.64237, -29.3969), Vector2(25.0, -25.00001), Vector2(29.39689, -19.64238), Vector2(32.66408, -13.5299), Vector2(34.676, -6.897484), Vector2(35.35534, 0.0), Vector2(34.67599, 6.897484), Vector2(32.66408, 13.52991), Vector2(29.39689, 19.64237), Vector2(25.0, 25.0), Vector2(19.64237, 29.39689), Vector2(13.5299, 32.66408), Vector2(12.58511, 32.95067), Vector2(0.0, 54.74874), Vector2(-12.58511, 32.95067), Vector2(-13.5299, 32.66408), Vector2(-19.64237, 29.39689), Vector2(-25.0, 25.0), Vector2(-29.39689, 19.64237), Vector2(-32.66408, 13.52991), Vector2(-32.95068, 12.58511), Vector2(-54.74874, 0.0), Vector2(-32.95067, -12.58511), Vector2(-32.66408, -13.5299), Vector2(-29.39689, -19.64238), Vector2(-25.0, -25.0), Vector2(-19.64238, -29.39689), Vector2(-13.52991, -32.66408), Vector2(-12.58511, -32.95067), Vector2(0.0, -54.74874)],
    "circle_pointy_4": [Vector2(12.58512, -32.95066), Vector2(13.52991, -32.66407), Vector2(19.64237, -29.3969), Vector2(25.0, -25.00001), Vector2(29.39689, -19.64238), Vector2(32.66408, -13.5299), Vector2(32.95067, -12.58511), Vector2(54.74874, 0.0), Vector2(32.95067, 12.58511), Vector2(32.66408, 13.52991), Vector2(29.39689, 19.64237), Vector2(25.0, 25.0), Vector2(19.64237, 29.39689), Vector2(13.5299, 32.66408), Vector2(12.58511, 32.95067), Vector2(0.0, 54.74874), Vector2(-12.58511, 32.95067), Vector2(-13.5299, 32.66408), Vector2(-19.64237, 29.39689), Vector2(-25.0, 25.0), Vector2(-29.39689, 19.64237), Vector2(-32.66408, 13.52991), Vector2(-32.95068, 12.58511), Vector2(-54.74874, 0.0), Vector2(-32.95067, -12.58511), Vector2(-32.66408, -13.5299), Vector2(-29.39689, -19.64238), Vector2(-25.0, -25.0), Vector2(-19.64238, -29.39689), Vector2(-13.52991, -32.66408), Vector2(-12.58511, -32.95067), Vector2(0.0, -54.74874)],
    "circle_pointy_4_small": [Vector2(9.634781, -23.0608), Vector2(13.88925, -20.78674), Vector2(17.67767, -17.67767), Vector2(20.78674, -13.88926), Vector2(23.06081, -9.634781), Vector2(39.74874, 0.0), Vector2(23.06079, 9.634789), Vector2(20.78674, 13.88926), Vector2(17.67767, 17.67767), Vector2(13.88926, 20.78674), Vector2(9.634789, 23.06079), Vector2(0.0, 39.74874), Vector2(-9.634781, 23.06081), Vector2(-13.88925, 20.78674), Vector2(-17.67767, 17.67767), Vector2(-20.78674, 13.88925), Vector2(-23.06079, 9.634789), Vector2(-39.74874, 0.0), Vector2(-23.0608, -9.634773), Vector2(-20.78674, -13.88926), Vector2(-17.67767, -17.67767), Vector2(-13.88926, -20.78674), Vector2(-9.634773, -23.06081), Vector2(0.0, -39.74874)],
    "cylinder": [Vector2(24.51963, 29.87726), Vector2(23.09698, 34.56709), Vector2(20.78674, 38.88926), Vector2(17.67767, 42.67767), Vector2(13.88926, 45.78674), Vector2(9.567085, 48.09698), Vector2(4.877258, 49.51963), Vector2(0.0, 50.0), Vector2(-4.877258, 49.51963), Vector2(-9.567085, 48.09699), Vector2(-13.88925, 45.78674), Vector2(-17.67767, 42.67767), Vector2(-20.78674, 38.88926), Vector2(-23.09698, 34.56709), Vector2(-24.51963, 29.87726), Vector2(-25.0, 25.0), Vector2(-25.0, -25.0), Vector2(-24.51963, -29.87726), Vector2(-23.09698, -34.56709), Vector2(-20.78674, -38.88926), Vector2(-17.67767, -42.67767), Vector2(-13.88925, -45.78674), Vector2(-9.567085, -48.09698), Vector2(-4.877258, -49.51963), Vector2(0.0, -50.0), Vector2(4.877258, -49.51963), Vector2(9.567085, -48.09699), Vector2(13.88926, -45.78674), Vector2(17.67767, -42.67767), Vector2(20.78674, -38.88925), Vector2(23.09698, -34.56709), Vector2(24.51963, -29.87726), Vector2(25.0, -25.0), Vector2(25.0, 25.0)],
    "cane": [Vector2(25.7461, -126.779), Vector2(30.6704, -124.645), Vector2(35.2087, -121.18), Vector2(39.1866, -116.517), Vector2(42.4511, -110.834), Vector2(44.8768, -104.351), Vector2(46.3706, -97.3159), Vector2(47.0, -90.0), Vector2(36.375, -90.0), Vector2(36.0724, -94.3895), Vector2(35.1761, -98.6104), Vector2(33.7206, -102.5), Vector2(31.7619, -105.91), Vector2(29.3752, -108.708), Vector2(26.6523, -110.787), Vector2(23.6977, -112.068), Vector2(20.625, -112.5), Vector2(17.5523, -112.068), Vector2(14.5977, -110.787), Vector2(11.8748, -108.708), Vector2(9.48807, -105.91), Vector2(7.52935, -102.5), Vector2(6.07389, -98.6104), Vector2(5.57568, -96.2641), Vector2(5.25, -92.7767), Vector2(5.25, 37.5), Vector2(-5.25, 37.5), Vector2(-5.25, -90.0), Vector2(-5.25, -92.2958), Vector2(-5.1791, -95.5107), Vector2(-5.00771, -97.8208), Vector2(-4.78816, -99.4493), Vector2(-3.62684, -104.351), Vector2(-1.20108, -110.834), Vector2(2.06344, -116.517), Vector2(6.04129, -121.18), Vector2(10.5796, -124.645), Vector2(15.5039, -126.779), Vector2(20.625, -127.5)]
}

static func get_points(symbol: String, scale: Vector2 = Vector2.ONE, skew: float = 0.0, rotation_deg: float = 0.0, displacement: Vector2 = Vector2.ZERO) -> PackedVector2Array:
    var shape_points: PackedVector2Array
    
    # Formulate the points
    shape_points = _formulate_raw_symbol_points(symbol)
    
    if shape_points.size() < 3:
        return []
    
    ## Transform the points
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation_deg), Vector2.ZERO)
    shape_points = rot_transform * shape_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), displacement)
    shape_points = transform * shape_points
    
    return shape_points
    
static func _formulate_raw_symbol_points(symbol: String) -> PackedVector2Array:
    var shape_points: PackedVector2Array = []
    
    var symbol_found = symbol_data.has(symbol)
    if not symbol_found:
        print("Symbol not found: '", symbol, "'. Searching in custom_symbols directory..")
        var symbol_data = SaveManager.load_symbol(symbol)
        
        if not symbol_data:
            return []
        
        var temp_string = symbol_data.get("symbol_points", []) as String
        shape_points = str_to_var(temp_string)
        return shape_points as PackedVector2Array
    
    # Get data  
    shape_points = symbol_data.get(symbol, [])          
    return shape_points
