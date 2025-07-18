@tool

extends BaseCreaturePart

class_name BaseCreatureMainBody

enum TYPE { CIRCLE, RECTANGLE, TRIANGLE, POLYGON, STAR, REULEAUX, HYPOCYCLOID, LINE, HOURGLASS, DIAMOND, SPIKE, SYMBOL, MIX, IRREGULAR }

### --- Main Data Objects ---
var params: Dictionary:
    set(v):
        if params == v:
            return
            
        params = v
        if is_node_ready():
            update_from_params(params)
        
var live_params: Dictionary
    
# --- Cached Vars --
var body_type: TYPE = TYPE.CIRCLE
var body_color: Color
var outline_width: float
var clip_child_parts: bool = true
# -- Shape Transform --
var shape_position := Vector2.ZERO
var shape_rotation := 0.0
var shape_scale := Vector2.ONE
var shape_skew := 0.0

## --- Internal State ---
var body_properties: Dictionary
var outline_node: ShapeLogicRenderer
var points_body: PackedVector2Array
var points_outline: PackedVector2Array
var bounding_box: Rect2 = Rect2()

# -- Shape Logic --
var body_shape_logic: CustomShapeLogic:
    set(v): body_shape_logic = v; queue_redraw()
var outline_shape_logic: CustomShapeLogic:
    set(v): outline_shape_logic = v; queue_redraw()

## --- Draw Bools ---
@export_subgroup("Draw Bools")
@export var draw_body: bool = true:
    set(new_value):
        draw_body = new_value
        queue_redraw()
@export var draw_outline: bool = true:
    set(new_value):
        if draw_outline == new_value:
            return
            
        draw_outline = new_value
        update_from_params(params)

# The constructor. Called when you do .new()
func _init(new_params: Dictionary = {}):
    params = new_params
    
func _ready() -> void:
    create_outline_node()
    update_from_params(params)
    
func _physics_process(_delta: float) -> void:
    if is_instance_valid(outline_node):
        outline_node.set_transform(transform)
    
# NOTE: The central update function. It calculates and stores the state.
func update_from_params(new_params: Dictionary):
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    # Declare part type
    part_type = PART_TYPE.MAIN_BODY
        
    if self.params.is_empty():
        points_body.clear()
        points_outline.clear()
        return
        
    # Update live params
    live_params = await get_live_values_of_dict(params)

    ## Update state variables from the dictionary
    body_type = live_params.get("body_type", TYPE.CIRCLE)
    body_color = live_params.get("body_color", Color.WHITE)
    outline_width = live_params.get("outline_width", 10.0)
    clip_child_parts = live_params.get("clip_child_parts", true)
    shape_position = live_params.get("shape_position", shape_position)
    shape_rotation = live_params.get("shape_rotation", shape_rotation)
    shape_scale = live_params.get("shape_scale", shape_scale)
    shape_skew = live_params.get("shape_skew", shape_skew)
    
    # Including the bools:
    self.draw_body = live_params.get("draw_body", draw_body)
    self.draw_outline = live_params.get("draw_outline", draw_outline)
    
    # Enforce clipping (or don't):
    if clip_child_parts: clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
    else: clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
    
    # Setting up properties:
    setup_body_properties()
    
    # Update the shape logic:
    update_shape_logic()
    
    # Update the outline node:
    update_outline_node()
    
func create_outline_node():
    var parent = get_parent()
    
    # Validate parent
    if not is_instance_valid(parent):
        printerr("Cannot create outline node without a parent.")
        return
        
    if not parent.is_node_ready():
        await parent.ready
    
    # Delete previous node
    if is_instance_valid(outline_node):
        parent.remove_child(outline_node)
        outline_node.queue_free()
        
    outline_node = ShapeLogicRenderer.new()
    outline_node.name = self.name + "_outline" # Give it a unique name

    parent.add_child(outline_node)

    parent.move_child(outline_node, self.get_index())
    
    if draw_outline: outline_node.logic_stack = [outline_shape_logic]
    else: outline_node.logic_stack = []
    
func update_outline_node():
    if not is_instance_valid(outline_node): # If it is nonexistent
        return
        
    var parent = get_parent()
    if draw_outline: outline_node.logic_stack = [outline_shape_logic]
    else: outline_node.logic_stack = []
    
func setup_body_properties():
    setup_part_properties()
    body_properties.clear()
    
    if procedurally_created:
        return
    
    var temp_params = params.duplicate()
    var _body_type_names: Dictionary = _get_enum_names(TYPE)
    
    # Save Body_Type first
    body_properties["body_type"] = _body_type_names.get(body_type, "UNKNOWN")
    temp_params.erase("body_type")
    
    body_properties.merge(save_props_by_type(temp_params, body_properties))
    
    part_properties["body_properties"] = body_properties
    
func update_shape_logic():
    # 1. Assemble the parameters for the body and outline's shapes.
    var all_params = form_shape_params()
    var body_params = all_params[0]
    var outline_params = all_params[1]
    
    # 2. Create/update the logic objects.
    if not is_instance_valid(body_shape_logic):
        body_shape_logic = CustomShapeLogic.new(body_params)
    else:
        body_shape_logic.update_from_params(body_params)
    
    if not is_instance_valid(outline_shape_logic):
        outline_shape_logic = CustomShapeLogic.new(outline_params)
    else:
        outline_shape_logic.update_from_params(outline_params)
        
    # Update the point-holding vars:
    points_body = body_shape_logic.get_points()
    points_outline = outline_shape_logic.get_points()
    bounding_box = body_shape_logic.get_bounding_box()
        
# This function's only job is to create the correct params dictionary.
func form_shape_params() -> Array[Dictionary]:
    var body_shape_params: Dictionary
    var outline_shape_params: Dictionary
    
    # Universal properties
    var common_params = {
        "color": body_color,
        "position": shape_position,
        "rotation": shape_rotation
    }
    
    # Shape-specific properties
    match (body_type):
        TYPE.POLYGON:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.POLYGON
            common_params["num_points"] = live_params.get("num_points", 3)
            common_params["radius"] = live_params.get("radius", 85)
        TYPE.CIRCLE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.CIRCLE
            common_params["radius"] = live_params.get("radius", 85)
            common_params["angle"] = live_params.get("angle", 360.0)
            common_params["num_points"] = live_params.get("num_points", 32)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.RECTANGLE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.RECTANGLE
            common_params["size"] = live_params.get("size", Vector2(170, 170))
        TYPE.STAR:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.STAR
            common_params["num_points"] = live_params.get("num_points", 5)
            common_params["outer_radius"] = live_params.get("outer_radius", 85)
            common_params["inner_radius"] = live_params.get("inner_radius", 42.5)
        TYPE.REULEAUX:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.REULEAUX
            common_params["num_lobes"] = live_params.get("num_lobes", 3)
            common_params["radius"] = live_params.get("radius", 85)
        TYPE.HOURGLASS:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.HOURGLASS
            common_params["width"] = live_params.get("width", 150.0)
            common_params["height"] = live_params.get("height", 150.0)
            common_params["notch_width"] = live_params.get("notch_width", 75.0)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.DIAMOND:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.DIAMOND
            common_params["width"] = live_params.get("width", 75.0)
            common_params["height"] = live_params.get("height", 150.0)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.SPIKE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.SPIKE
            common_params["base_width"] = live_params.get("base_width", 150.0)
            common_params["base_height"] = live_params.get("base_height", 75.0)
            common_params["spike_height"] = live_params.get("spike_height", 75.0)
            common_params["bottom_displ"] = live_params.get("bottom_displ", Vector2.ZERO)
            common_params["top_displ"] = live_params.get("top_displ", Vector2.ZERO)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.SYMBOL:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.SYMBOL
            common_params["symbol"] = live_params.get("symbol", "a")
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.MIX:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.MIX
            common_params["boolean_operation"] = live_params.get("boolean_operation", CustomShapeLogic.BooleanOperation.UNION)
            common_params["stack"] = live_params.get("stack")
        TYPE.IRREGULAR:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.IRREGULAR
            common_params["points"] = live_params.get("points", [Vector2(-30, 25), Vector2(30, 25), Vector2(0, -25)])
            
    body_shape_params = common_params.duplicate()
    outline_shape_params = common_params.duplicate()
    
    # Distinguish outline shape's params
    outline_shape_params["filled"] = false
    outline_shape_params["outline_width"] = outline_width * 2 # Half width is covered by body
    outline_shape_params["color"] = Color.BLACK
            
    return [body_shape_params, outline_shape_params]
    
func _draw():
    #if draw_outline and is_instance_valid(outline_shape_logic) and is_instance_valid(outline_node): outline_shape_logic.draw_on(outline_node)
    if draw_body and is_instance_valid(body_shape_logic): body_shape_logic.draw_on(self)

## --- Utility ---
# For returning the names of enums
func _get_enum_names(enum_dict: Dictionary) -> Dictionary:
    var names = {}
    for key in enum_dict:
        var value = enum_dict[key]
        names[value] = key
    return names
    
# For saving data by type
func save_props_by_type(source_dict: Dictionary, target_dict: Dictionary) -> Dictionary:
    # Loop through each property
    for prop in source_dict.keys():
        var val = source_dict.get(prop)
        val = get_value_componentized(val)
        target_dict[prop] = val
        
    return target_dict
            
func get_value_componentized(value: Variant) -> Variant:
    var val = value
    if val is Vector2:
        return { "x": val.x, "y": val.y }
    elif val is Color:
        return { "r": val.r, "g": val.g, "b": val.b, "a": val.a }
    else:
        return val

func get_bb_info() -> Dictionary:
    var bb_info = {
        "bounding_box": bounding_box,
        "size": bounding_box.size,
        "length_x": bounding_box.size.x,
        "length_y": bounding_box.size.y
    }
    return bb_info
