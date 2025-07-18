@tool
extends Node2D
class_name ShapeLogicRenderer

enum DrawMode { INDIVIDUAL, UNION, INTERSECTION, SYMMETRIC_DIFFERENCE, SUBTRACTION }

# Master Input: LOGIC_STACK (AKA: ShapeLogics)
@export var logic_stack: Array[CustomShapeLogic]:
    set(v):
        if logic_stack == v:
            return
        logic_stack = v
        _update_shape_logics()
        
# --- Secondary Input ---
@export var draw_mode := DrawMode.INDIVIDUAL
@export var override_color: Color = Color.WHITE

# --- Store Data ---
var _params_stack: Array[Dictionary] = []
var _points_stack: Array[PackedVector2Array] = []
var _resultant_shape_logic: CustomShapeLogic # After operation..
var _resultant_shape_points: PackedVector2Array

func _draw():
    if logic_stack.is_empty(): return
    
    if draw_mode == DrawMode.INDIVIDUAL:
        draw_shapes_individually()
        return
    
    draw_resultant_shape_after_operation()
        
func draw_shapes_individually():
    for shape_logic in logic_stack:
        if is_instance_valid(shape_logic):
            shape_logic.draw_on(self)
        
func draw_resultant_shape_after_operation():
    if is_instance_valid(_resultant_shape_logic):
        _resultant_shape_logic.draw_on(self)

func _update_shape_logics():
    _rebuild_points_n_params_stack()
    if draw_mode != DrawMode.INDIVIDUAL:
        _calculate_resultant_shape()
    queue_redraw()

func _rebuild_points_n_params_stack():
    _points_stack.clear()
    _params_stack.clear()
    _resultant_shape_points.clear()
    if logic_stack.is_empty(): return

    for shape_logic in logic_stack:
        if not is_instance_valid(shape_logic):
            continue # Skip
            
        # Manipulate shape params:
        if not shape_logic.params.has("color"):
            shape_logic["color"] = override_color
        
        # Append
        _points_stack.append(shape_logic.get_points())
        _params_stack.append(shape_logic.params)
    
func _calculate_resultant_shape():
    _resultant_shape_points.clear()
    _resultant_shape_points = _apply_boolean_operation(_points_stack)
    
    if _resultant_shape_points.size() < 3:
        _resultant_shape_logic = null # Clear the old logic if the new shape is invalid
        return
    
    if not is_instance_valid(_resultant_shape_logic):
        _resultant_shape_logic = CustomShapeLogic.new()
    
    _resultant_shape_logic.params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.IRREGULAR,
        "color": override_color,
        "points": _resultant_shape_points
    }

# Perform Operation:       
func _apply_boolean_operation(points_stack: Array[PackedVector2Array]) -> PackedVector2Array:
    var result_polygon: PackedVector2Array
    if points_stack.size() < 2:
        return points_stack[0] if points_stack.size() == 1 else []
    
    result_polygon = points_stack[0]
    for i in range(1, points_stack.size()):
        var points_i = points_stack[i]
        
        var result_polygons: Array[PackedVector2Array]
        # Match draw_mode and perform necessary operation
        match(draw_mode):
            DrawMode.INDIVIDUAL: result_polygons = Geometry2D.merge_polygons(result_polygon, points_i)
            DrawMode.UNION: result_polygons = Geometry2D.merge_polygons(result_polygon, points_i)
            DrawMode.INTERSECTION: result_polygons = Geometry2D.intersect_polygons(result_polygon, points_i)
            DrawMode.SYMMETRIC_DIFFERENCE: result_polygons = Geometry2D.exclude_polygons(result_polygon, points_i)
            DrawMode.SUBTRACTION: result_polygons = Geometry2D.clip_polygons(result_polygon, points_i)
            
        if result_polygons.is_empty():
            printerr("Boolean operation failed and returned an empty result.")
            return [] # Abort and return an empty polygon.

        if result_polygons.size() > 1:
            printerr("Operation resulted in multiple disjoint polygons.")
            return []
            
        result_polygon = result_polygons[0]
    
    return result_polygon
    
# Useful Utility:
func get_logic_stack_from_param_stack(stack: Array[Dictionary]) -> Array[CustomShapeLogic]:
    var created_shape_logics: Array[CustomShapeLogic]
    
    for params in stack:
        var shape_logic = CustomShapeLogic.new(params)
        created_shape_logics.append(shape_logic)
    
    return created_shape_logics
    
func get_multilogic_stack_from_param_stack(stack: Array[Dictionary]) -> Array[MultiShapeLogic]:
    var created_shape_logics: Array[MultiShapeLogic]
    
    for params in stack:
        var shape_logic = MultiShapeLogic.new(params)
        created_shape_logics.append(shape_logic)
    
    return created_shape_logics
