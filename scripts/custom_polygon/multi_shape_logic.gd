@tool
class_name MultiShapeLogic
extends Resource

const TriangleGenerator = preload("res://scripts/shape_generators/TriangleGenerator.gd")
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")
const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")
const LineGenerator = preload("res://scripts/shape_generators/LineGenerator.gd")
const SymbolShapeGenerator = preload("res://scripts/shape_generators/SymbolShapeGenerator.gd")
const HourglassGenerator = preload("res://scripts/shape_generators/HourglassGenerator.gd")
const DiamondGenerator = preload("res://scripts/shape_generators/DiamondGenerator.gd")
const SpikeGenerator = preload("res://scripts/shape_generators/SpikeGenerator.gd")
const CircleGenerator = preload("res://scripts/shape_generators/CircleGenerator.gd")

enum BooleanOperation { INDIVIDUAL, UNION, INTERSECTION, SYMMETRIC_DIFFERENCE, SUBTRACTION }
enum SHAPE_TYPE { CIRCLE, RECTANGLE, TRIANGLE, POLYGON, STAR, REULEAUX, HYPOCYCLOID, LINE, HOURGLASS, DIAMOND, SPIKE, SYMBOL, MIX, IRREGULAR }

@export var params: Dictionary:
    set(v):
        if params == v:
            return
        params = v
        update_from_params(params)

var polygons: Array[PackedVector2Array]
var color: Color = Color.WHITE
var is_filled: bool = true
var outline_width: float = 20.0
var bounding_box: Rect2

func _init(new_params: Dictionary = {}):
    update_from_params(new_params)

func update_from_params(new_params: Dictionary):
    if params != new_params:
        params = new_params
        
    if params.is_empty():
        polygons.clear()
        return

    self.color = params.get("color", Color.WHITE)
    self.is_filled = params.get("filled", true)
    self.outline_width = params.get("outline_width", 20.0)
    
    var shape_type = params.get("shape_type", SHAPE_TYPE.CIRCLE)
    
    if shape_type == SHAPE_TYPE.MIX:
        var operation: BooleanOperation = params.get("boolean_operation", BooleanOperation.UNION)
        var stack_params: Array = params.get("stack", [])
        var points_stack: Array[PackedVector2Array]

        for shape_params in stack_params:
            var temp_logic = MultiShapeLogic.new(shape_params)
            if not temp_logic.polygons.is_empty():
                points_stack.append_array(temp_logic.polygons)
        
        self.polygons = _apply_boolean_operation(points_stack, operation)
    else:
        var raw_points = _generate_raw_points(shape_type, params)
        if not raw_points.is_empty():
            var transformed_points = _get_transformed_points(raw_points, params)
            self.polygons = [transformed_points]
        else:
            self.polygons = []
            
    _calculate_bounding_box()

# In MultiShapeLogic.gd

func draw_on(canvas: CanvasItem):
    if polygons.is_empty():
        return

    if is_filled:
        # --- Step 1: Consolidate all points into a single array ---
        var all_points = PackedVector2Array()
        for poly_loop in polygons:
            all_points.append_array(poly_loop)
            
        if all_points.is_empty():
            return
            
        # --- Step 2: Triangulate using the consolidated points ---
        # This returns an array of indices that point to vertices in 'all_points'.
        var triangle_indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygons)

        if triangle_indices.is_empty():
            return

        # --- Step 3: Build the final vertex array for drawing ---
        # We iterate through the indices and pull the corresponding vertex from 'all_points'
        # to create the list of triangles that 'draw_primitive' expects.
        var triangle_vertices = PackedVector2Array()
        triangle_vertices.resize(triangle_indices.size())
        for i in range(triangle_indices.size()):
            var vertex_index = triangle_indices[i]
            triangle_vertices[i] = all_points[vertex_index]

        # --- Step 4: Draw the triangles ---
        if not triangle_vertices.is_empty():
            var triangle_colors = PackedColorArray()
            triangle_colors.resize(triangle_vertices.size())
            triangle_colors.fill(color)
            
            canvas.draw_primitive(triangle_vertices, triangle_colors, PackedVector2Array())
    else: # Draw outline
        # The outline logic was already correct.
        for poly_loop in polygons:
            if poly_loop.size() < 2: 
                continue
            
            var outline_points = poly_loop.duplicate()
            if not outline_points[0].is_equal_approx(outline_points[outline_points.size() - 1]):
                outline_points.append(outline_points[0])
                
            canvas.draw_polyline(outline_points, color, outline_width)

func _generate_raw_points(type: SHAPE_TYPE, given_params: Dictionary) -> PackedVector2Array:
    match type:
        SHAPE_TYPE.CIRCLE:
            var num_sides = given_params.get("num_points", 32)
            var radius = given_params.get("radius", 50.0)
            var angle = given_params.get("angle", 360.0)
            return CircleGenerator.get_points(radius, angle, num_sides)
        SHAPE_TYPE.RECTANGLE:
            var size = given_params.get("size", Vector2(50, 50))
            var half = size / 2.0
            return [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
        SHAPE_TYPE.TRIANGLE:
            var tri_info = {
                "gen_type": given_params.get("gen_type", TriangleGenerator.GenerationType.EQUILATERAL_FROM_CIRCUMRADIUS),
                "radius": given_params.get("radius", 25.0),
                "size": given_params.get("size", Vector2(50, 50)),
                "side_length": given_params.get("side_length", 50.0)
            }
            return TriangleGenerator.get_points(tri_info)
        SHAPE_TYPE.POLYGON:
            var num_points = given_params.get("num_points", 5)
            var radius = given_params.get("radius", 50.0)
            return PolygonGenerator.generate_polygon_points(num_points, radius)
        SHAPE_TYPE.STAR:
            var num_points = given_params.get("num_points", 5)
            var outer_radius = given_params.get("outer_radius", 50.0)
            var inner_radius = given_params.get("inner_radius", 25.0)
            return StarGenerator.get_star_points(num_points, outer_radius, inner_radius)
        SHAPE_TYPE.REULEAUX:
            var num_lobes = given_params.get("num_lobes", 3)
            var radius = given_params.get("radius", 50.0)
            return PolygonGenerator.generate_reuleaux_polygon_points(num_lobes, radius)
        SHAPE_TYPE.LINE:
            var length = given_params.get("length", 50.0)
            var width = given_params.get("width", 2.5)
            var slant = given_params.get("slant", 0.0) 
            return LineGenerator.get_points(length, width, Vector2.ONE, slant, -90)
        SHAPE_TYPE.HOURGLASS:
            var width = given_params.get("width", 50.0)
            var height = given_params.get("height", 50.0)
            var notch_width = given_params.get("notch_width", 25.0)
            return HourglassGenerator.get_points(width, height, notch_width)
        SHAPE_TYPE.DIAMOND:
            var width = given_params.get("width", 50.0)
            var height = given_params.get("height", 25.0)
            return DiamondGenerator.get_points(width, height)
        SHAPE_TYPE.SPIKE:
            var base_width = given_params.get("base_width", 120.0)
            var base_height = given_params.get("base_height", 40.0)
            var spike_height = given_params.get("spike_height", 200.0)
            return SpikeGenerator.get_points(base_width, base_height, spike_height)
        SHAPE_TYPE.SYMBOL:
            var symbol = given_params.get("symbol", "a")
            return SymbolShapeGenerator.get_points(symbol)
        SHAPE_TYPE.IRREGULAR:
            return given_params.get("points", [])
    return []

func _get_transformed_points(raw_points: PackedVector2Array, given_params: Dictionary) -> PackedVector2Array:
    var position = given_params.get("position", Vector2.ZERO)
    var rotation = given_params.get("rotation", 0.0)
    var scale = given_params.get("scale", Vector2.ONE)
    var skew = given_params.get("skew", 0.0)
    var rot_transform = Transform2D(deg_to_rad(rotation), Vector2.ZERO)
    var final_transform = Transform2D(0.0, scale, deg_to_rad(skew), position)
    return final_transform * (rot_transform * raw_points)

func get_visual_center() -> Vector2:
    if not polygons.is_empty() and not polygons[0].is_empty():
        return get_bounding_box().get_center()
    return params.get("position", Vector2.ZERO)

func _calculate_bounding_box():
    bounding_box = Rect2()
    if not polygons.is_empty():
        var all_points = PackedVector2Array()
        for poly in polygons:
            all_points.append_array(poly)
        if not all_points.is_empty():
            bounding_box.position = all_points[0]
            for p in all_points:
                bounding_box = bounding_box.expand(p)

func get_bounding_box() -> Rect2:
    return bounding_box

func get_polygons() -> Array[PackedVector2Array]:
    return polygons
    
func _apply_boolean_operation(points_stack: Array[PackedVector2Array], operation: BooleanOperation) -> Array[PackedVector2Array]:
    if operation == BooleanOperation.INDIVIDUAL:
        return points_stack

    if points_stack.size() < 2:
        return points_stack

    var result_polygons = [points_stack[0]]
    for i in range(1, points_stack.size()):
        var new_results: Array[PackedVector2Array] = []
        var clip_polygon = points_stack[i]
        
        for subject_polygon in result_polygons:
            var operation_result: Array[PackedVector2Array]
            match operation:
                BooleanOperation.UNION:
                    operation_result = Geometry2D.merge_polygons(subject_polygon, clip_polygon)
                BooleanOperation.INTERSECTION:
                    operation_result = Geometry2D.intersect_polygons(subject_polygon, clip_polygon)
                BooleanOperation.SYMMETRIC_DIFFERENCE:
                    operation_result = Geometry2D.exclude_polygons(subject_polygon, clip_polygon)
                BooleanOperation.SUBTRACTION:
                    operation_result = Geometry2D.clip_polygons(subject_polygon, clip_polygon)
            new_results.append_array(operation_result)
        
        result_polygons = new_results
        if result_polygons.is_empty():
            break

    return result_polygons
