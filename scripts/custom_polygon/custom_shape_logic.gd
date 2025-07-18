@tool

class_name CustomShapeLogic
extends Resource

var SG = ShapeGens

enum BooleanOperation { INDIVIDUAL, UNION, INTERSECTION, SYMMETRIC_DIFFERENCE, SUBTRACTION }
enum SHAPE_TYPE { CIRCLE, RECTANGLE, TRIANGLE, POLYGON, STAR, REULEAUX, HYPOCYCLOID, LINE, HOURGLASS, DIAMOND, SPIKE, SYMBOL, MIX, IRREGULAR }

# --- State Variables ---
@export var params: Dictionary:
    set(v):
        if params == v:
            return
            
        params = v
        update_from_params(params)
        
# --- Cached Vars ---
var points: PackedVector2Array
var color: Color = Color.WHITE
var is_filled: bool = true
var outline_width: float = 20.0
var bounding_box: Rect2

# The constructor. Called when you do .new()
func _init(new_params: Dictionary = {}):
    update_from_params(new_params)

# The main update function. It calculates and stores the state.
func update_from_params(new_params: Dictionary):
    if params != new_params:
        params = new_params
        
    if params.is_empty():
        points.clear()
        return

    # Update state variables from the dictionary
    self.color = params.get("color", Color.WHITE)
    self.is_filled = params.get("filled", true)
    self.outline_width = params.get("outline_width", 20.0)
    
    # Generate the points based on the parameters
    var shape_type = params.get("shape_type", SHAPE_TYPE.CIRCLE)
    var raw_points = _generate_raw_points(shape_type, params)
    
    if raw_points.is_empty():
        points.clear()
        return
    
    # Apply the transform manually and store the final points.
    self.points = get_transformed_points(raw_points, params)
    #self.points = transform.xform(raw_points)

# This is the new function that the VIEW will call.
# It takes a CanvasItem (any Node2D that can draw) as an argument.
func draw_on(canvas: CanvasItem):
    if points.size() < 3:
        return

    if is_filled:
        canvas.draw_polygon(points, [color])
    else:
        var outline_points = points.duplicate()
        outline_points.append(outline_points[0])
        canvas.draw_polyline(outline_points, color, outline_width)

# This function MUST return a valid array of points for clipping to work.
func _generate_raw_points(type: SHAPE_TYPE, given_params: Dictionary) -> PackedVector2Array:
    match type:
        SHAPE_TYPE.CIRCLE:
            var num_sides = given_params.get("num_points", 32)
            var radius = given_params.get("radius", 50.0 / sqrt(2))
            var angle = given_params.get("angle", 360.0)
            return SG.CircleGenerator.get_points(radius, angle, num_sides)
            
        SHAPE_TYPE.RECTANGLE:
            var size = given_params.get("size", Vector2(50, 50))
            var half = size / 2.0
            var raw_points: PackedVector2Array
            raw_points.append(Vector2(-half.x, -half.y))
            raw_points.append(Vector2( half.x, -half.y))
            raw_points.append(Vector2( half.x,  half.y))
            raw_points.append(Vector2(-half.x,  half.y))
            return raw_points
            
        SHAPE_TYPE.TRIANGLE:
            var tri_info: Dictionary
            tri_info["gen_type"] = given_params.get("gen_type", SG.TriangleGenerator.GenerationType.EQUILATERAL_FROM_CIRCUMRADIUS)
            tri_info["radius"] = given_params.get("radius", 25) as float
            tri_info["size"] = given_params.get("size", Vector2(50, 50)) as Vector2
            tri_info["side_length"] = given_params.get("side_length", 50)
            return SG.TriangleGenerator.get_points(tri_info)
            
        SHAPE_TYPE.POLYGON:
            # Assuming you have your PolygonGenerator available
            var num_points = given_params.get("num_points", 3)
            var radius = given_params.get("radius", 50.0)
            var snap_closest = given_params.get("snap_closest", false)
            return SG.PolygonGenerator.generate_polygon_points(num_points, radius, Vector2.ZERO, 0.0, snap_closest)
            
        SHAPE_TYPE.STAR:
            var num_points = given_params.get("num_points", 5)
            var outer_radius = given_params.get("outer_radius", 50.0)
            var inner_radius = given_params.get("inner_radius", 25.0)
            return SG.StarGenerator.get_star_points(num_points, outer_radius, inner_radius, Vector2.ZERO, 0.0)
        
        SHAPE_TYPE.REULEAUX:
            var num_lobes = given_params.get("num_lobes", 3)
            var radius = given_params.get("radius", 50.0)
            return SG.PolygonGenerator.generate_reuleaux_polygon_points(num_lobes, radius, Vector2.ZERO, 0.0)
        
        SHAPE_TYPE.LINE:
            var length = given_params.get("length", 50.0)
            var width = given_params.get("width", 2.5)
            var slant = given_params.get("slant", 0.0) 
            return SG.LineGenerator.get_points(length, width, Vector2.ONE, slant, -90)
            
        SHAPE_TYPE.HOURGLASS:
            var width = given_params.get("width", 50.0)
            var height = given_params.get("height", 50.0)
            var notch_width = given_params.get("notch_width", 25.0)
            var bottom_displ = given_params.get("bottom_displ", Vector2.ZERO)
            var top_displ = given_params.get("top_displ", Vector2.ZERO)
            return SG.HourglassGenerator.get_points(width, height, notch_width, bottom_displ, top_displ)
         
        SHAPE_TYPE.DIAMOND:
            var width = given_params.get("width", 50.0)
            var height = given_params.get("height", 25.0)
            var bottom_displ = given_params.get("bottom_displ", Vector2.ZERO)
            var top_displ = given_params.get("top_displ", Vector2.ZERO)
            return SG.DiamondGenerator.get_points(width, height, bottom_displ, top_displ)
        
        SHAPE_TYPE.SPIKE:
            var base_width = given_params.get("base_width", 120)
            var base_height = given_params.get("base_height", 40)
            var spike_height = given_params.get("spike_height", 200)
            var bottom_displ = given_params.get("bottom_displ", Vector2.ZERO)
            var top_displ = given_params.get("top_displ", Vector2.ZERO)
            return SG.SpikeGenerator.get_points(base_width, base_height, spike_height, bottom_displ, top_displ)
        
        SHAPE_TYPE.SYMBOL:
            var symbol = given_params.get("symbol", "a")
            return SG.SymbolShapeGenerator.get_points(symbol)
        
        SHAPE_TYPE.MIX:
            var operation: BooleanOperation = given_params.get("boolean_operation", BooleanOperation.UNION)
            var params_stack: Array = given_params.get("stack")
            var points_stack: Array[PackedVector2Array]
            for shape_params: Dictionary in params_stack:
                var shape_type = shape_params.get("shape_type", CustomShapeLogic.SHAPE_TYPE.CIRCLE)
                var shape_points = _generate_raw_points(shape_type, shape_params)
                shape_points = get_transformed_points(shape_points, shape_params)
                points_stack.append(shape_points)
            var resultant_points: PackedVector2Array = _apply_boolean_operation(points_stack, operation)
            return resultant_points
            
        SHAPE_TYPE.IRREGULAR:
            return given_params.get("points", [])
            
    return []
    
func get_transformed_points(raw_points: PackedVector2Array, given_params: Dictionary) -> PackedVector2Array:
    # Get vars:
    var position: Vector2 = given_params.get("position", Vector2.ZERO)
    var rotation: float = given_params.get("rotation", 0.0)
    var scale: Vector2 = given_params.get("scale", Vector2.ONE)
    var skew: float = given_params.get("skew", 0.0)
    
    # Apply Rotation Separately (For slanting/skewing to work correctly)
    var rot_transform = Transform2D(deg_to_rad(rotation), Vector2.ZERO)
    raw_points = rot_transform * raw_points
    
    # Apply transform
    var transform = Transform2D(0.0, scale, deg_to_rad(skew), position)
    var transformed_points = transform * raw_points
        
    return transformed_points
    
func get_visual_center() -> Vector2:
    if not points.is_empty():
        var sum_of_points = Vector2.ZERO
        for point in points:
            sum_of_points += point
        return sum_of_points / points.size()
    else:
        return params.get("position", Vector2.ZERO)
            
func get_bounding_box():
    bounding_box = Rect2()
    if points:
        for p in points:
            bounding_box = bounding_box.expand(p)
    return bounding_box
    
func get_points():
    return self.points
    
func get_shape_magnitude() -> float:
    var shape_type = params.get("shape_type", SHAPE_TYPE.CIRCLE)
    match shape_type:
        #SHAPE_TYPE.POLYGON:
            #var radius = params.get("radius", 50.0)
            #var num_points = params.get("num_points", 3)
            #var angle = PI / num_points
            #var apothem = radius * cos(angle)
            #var correction = 1.0 + (3.0 / num_points)
            #return (radius - apothem) * correction
        SHAPE_TYPE.CIRCLE:
            return params.get("radius", 50.0) * 2
            
        SHAPE_TYPE.RECTANGLE:
            var size: Vector2 = params.get("size", Vector2(50,50))
            return min(size.x, size.y)
            
        SHAPE_TYPE.STAR:
            # The correct logic for stars that we developed.
            var outer_rad = params.get("outer_radius", 50.0)
            var inner_rad = params.get("inner_radius", 25.0)
            
            var base_magnitude = abs(outer_rad - inner_rad)
            var final_mag = base_magnitude * 1.6          
            return final_mag
            
    # Default/fallback
    return get_bounding_box().size.length() * 0.5
    
# Perform Operation:       
func _apply_boolean_operation(points_stack: Array[PackedVector2Array], operation: BooleanOperation) -> PackedVector2Array:
    var result_polygon: PackedVector2Array
    if points_stack.size() < 2:
        var original_polygon: PackedVector2Array = []
        if points_stack.size() == 1: original_polygon = points_stack[0]
        return original_polygon
    
    result_polygon = points_stack[0]
    for i in range(1, points_stack.size()):
        var points_i = points_stack[i]
        
        var result_polygons: Array[PackedVector2Array]
        # Match operation var and then perform it
        match(operation):
            BooleanOperation.INDIVIDUAL: result_polygons = Geometry2D.merge_polygons(result_polygon, points_i)
            BooleanOperation.UNION: result_polygons = Geometry2D.merge_polygons(result_polygon, points_i)
            BooleanOperation.INTERSECTION: result_polygons = Geometry2D.intersect_polygons(result_polygon, points_i)
            BooleanOperation.SYMMETRIC_DIFFERENCE: result_polygons = Geometry2D.exclude_polygons(result_polygon, points_i)
            BooleanOperation.SUBTRACTION: result_polygons = Geometry2D.clip_polygons(result_polygon, points_i)
            
        if result_polygons.is_empty():
            printerr("Boolean operation failed and returned an empty result.")
            return [] # Abort and return an empty polygon.

        if result_polygons.size() > 1:
            printerr("Operation resulted in multiple disjoint polygons.")
            return []
            
        result_polygon = result_polygons[0]
    
    return result_polygon
    
