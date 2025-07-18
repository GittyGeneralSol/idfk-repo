@tool

extends BaseCreaturePart

class_name BaseCreatureEye

enum TYPE { CIRCLE, RECTANGLE, TRIANGLE, POLYGON, STAR, REULEAUX, HYPOCYCLOID, LINE, HOURGLASS, DIAMOND, SPIKE, SYMBOL, MIX, IRREGULAR }

enum LID_TYPE { UNILID, TWOLID, OMNI, CIRCLE, RECTANGLE, TRIANGLE }

enum BLINK_TYPE { OPENNESS, SCALING }

### --- Main Data Objects ---
var params: Dictionary:
    set(v):
        if params == v:
            return
            
        params = v
        if is_node_ready():
            update_from_params(params)
        
var live_params: Dictionary
var shape_params: Dictionary # Consider using shape: { ...params... } structure.
var live_shape_params: Dictionary
    
## --- Cached Vars --
var eye_type: TYPE = TYPE.CIRCLE
var eye_color: Color
var outline_width: float
var outline_color: Color = Color.BLACK
var has_eyelids: bool = true
# -- Shape Transform --
var shape_position: Vector2 = Vector2.ZERO
var shape_rotation: float = 0.0
var shape_scale: Vector2 = Vector2.ONE
var shape_skew: float = 0.0

# -- Lids --
var lid_type: LID_TYPE = LID_TYPE.TWOLID
var eyelid_color_top: Color
var eyelid_color_bottom: Color

# -- Blinking Type --
var blink_type: BLINK_TYPE = BLINK_TYPE.OPENNESS

## --- Internal State ---
var eye_properties: Dictionary
var points_eye: PackedVector2Array
var points_outline: PackedVector2Array
var _current_blink_tween: Tween
var outline_node: ShapeLogicRenderer
var _blinking: bool = false

# -- Shape Logic --
var eye_shape_logic: CustomShapeLogic:
    set(v): eye_shape_logic = v; queue_redraw()
var outline_shape_logic: CustomShapeLogic:
    set(v): outline_shape_logic = v; queue_redraw()

## --- Control ---
@export_subgroup("Timing")
@export var time_to_blink: float = 0.2
@export var hold_closed_time: float = 0.1

@export_subgroup("Eyelid Control")
@export_range(0.0, 1.0, 0.01) var master_openness = 1.0:
    set(new_value):
        if new_value is not float:
            return
        
        master_openness = new_value
        for eyelid: BaseCreatureEyelids in get_child_eyelids():
            eyelid.openness = master_openness
    get:
        return master_openness
        
# --- Signals ---:
signal blinked
        
## --- Draw Bools ---
@export_subgroup("Draw Bools")
@export var draw_eye: bool = true:
    set(new_value):
        draw_eye = new_value
        queue_redraw()
@export var draw_outline: bool = false:
    set(new_value):
        if draw_outline == new_value:
            return
            
        draw_outline = new_value
        update_outline_node()

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
    
    # Declare part type and clip mode
    part_type = PART_TYPE.EYE
    clip_children = ClipChildrenMode.CLIP_CHILDREN_AND_DRAW
    
    # Handle connections:
    if not blinked.is_connected(_on_blink_end):
        blinked.connect(_on_blink_end)
        
    if self.params.is_empty():
        points_eye.clear()
        points_outline.clear()
        return
        
    # Update live params
    live_params = await get_live_values_of_dict(params)
    #shape_params = shape_params.get("shape", {})
    #live_shape_params = await get_live_values_of_dict(shape_params)

    ## Update state variables from the dictionary
    self.eye_type = live_params.get("eye_type", TYPE.CIRCLE)
    self.eye_color = live_params.get("eye_color", Color.WHITE)
    self.outline_width = live_params.get("outline_width", 10.0)
    self.outline_color = live_params.get("outline_color", Color.BLACK)
    self.has_eyelids = live_params.get("has_eyelids", true)
    shape_position = live_params.get("shape_position", shape_position)
    shape_rotation = live_params.get("shape_rotation", shape_rotation)
    shape_scale = live_params.get("shape_scale", shape_scale)
    shape_skew = live_params.get("shape_skew", shape_skew)
    
    # Including eyelid vars and blink type
    self.lid_type = live_params.get("lid_type", LID_TYPE.TWOLID)
    self.eyelid_color_top = live_params.get("eyelid_color_top", Color.SKY_BLUE)
    self.eyelid_color_bottom = live_params.get("eyelid_color_bottom", Color.SKY_BLUE)
    self.blink_type = live_params.get("blink_type", BLINK_TYPE.OPENNESS)
    
    # Including control variables
    self.time_to_blink = live_params.get("time_to_blink", 0.2)
    self.hold_closed_time = live_params.get("hold_closed_time", 0.1)
    self.master_openness = live_params.get("initial_openness", 1.0)
    
    # Including the bools:
    self.draw_eye = live_params.get("draw_eye", draw_eye)
    self.draw_outline = live_params.get("draw_outline", draw_outline)
    
    # Setting up properties:
    setup_eye_properties()
    
    # Update the shape logic:
    update_shape_logic()
    
    # Update the outline node:
    update_outline_node()
    
    # Handle the eyelids:
    handle_eyelids()
    
func setup_eye_properties():
    setup_part_properties()
    eye_properties.clear()
    
    if procedurally_created:
        return
    
    var _eye_type_names: Dictionary = _get_enum_names(TYPE)
    var _lid_type_names: Dictionary = _get_enum_names(LID_TYPE)
    var _blink_type_names: Dictionary = _get_enum_names(BLINK_TYPE)
    
    # Create the eyelid properties dictionary
    var eyelid_params: Dictionary = {
        "lid_type": _lid_type_names.get(lid_type, "UNKNOWN"),
        "eyelid_color_top": get_value_componentized(eyelid_color_top),
        "eyelid_color_bottom": get_value_componentized(eyelid_color_bottom)
    }
    
    # Clean unnesscary props:
    var temp_params = params.duplicate()
    temp_params.erase("lid_type")
    temp_params.erase("eyelid_color_top")
    temp_params.erase("eyelid_color_bottom")
    
    # Save the eye_type and blink_type first
    eye_properties["eye_type"] = _eye_type_names.get(eye_type, "UNKNOWN")
    eye_properties["blink_type"] = _blink_type_names.get(blink_type, "UNKNOWN")
    temp_params.erase("eye_type")
    temp_params.erase("blink_type")
    
    eye_properties.merge(save_props_by_type(temp_params, eye_properties))
    
    eye_properties["eyelid_props"] = eyelid_params
    part_properties["eye_properties"] = eye_properties
    
func update_shape_logic():
    # 1. Assemble the parameters for the eye and outline's shapes.
    var all_params = form_shape_params()
    var eye_params = all_params[0]
    var outline_params = all_params[1]
    
    # 2. Create/update the logic objects.
    if not is_instance_valid(eye_shape_logic):
        eye_shape_logic = CustomShapeLogic.new(eye_params)
    else:
        eye_shape_logic.update_from_params(eye_params)
    
    if not is_instance_valid(outline_shape_logic):
        outline_shape_logic = CustomShapeLogic.new(outline_params)
    else:
        outline_shape_logic.update_from_params(outline_params)
        
    # Update the point-holding vars:
    points_eye = eye_shape_logic.get_points()
    points_outline = outline_shape_logic.get_points()
    
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
        
# This function's only job is to create the correct params dictionary.
func form_shape_params() -> Array[Dictionary]:
    var eye_shape_params: Dictionary
    var outline_shape_params: Dictionary
    
    # Universal properties
    var common_params = {
        "color": eye_color,
        "position": shape_position,
        "rotation": shape_rotation,
        "scale": shape_scale,
        "skew": shape_skew
    }
    
    # Shape-specific properties
    match (eye_type):
        TYPE.POLYGON:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.POLYGON
            common_params["num_points"] = live_params.get("num_points", 3)
            common_params["radius"] = live_params.get("radius", 25)
        TYPE.CIRCLE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.CIRCLE
            common_params["radius"] = live_params.get("radius", 50 / sqrt(2))
            common_params["angle"] = live_params.get("angle", 360.0)
            common_params["num_points"] = live_params.get("num_points", 32)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.RECTANGLE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.RECTANGLE
            common_params["size"] = live_params.get("size", Vector2(50, 50))
        TYPE.STAR:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.STAR
            common_params["num_points"] = live_params.get("num_points", 5)
            common_params["outer_radius"] = live_params.get("outer_radius", 25)
            common_params["inner_radius"] = live_params.get("inner_radius", 12.5)
        TYPE.REULEAUX:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.REULEAUX
            common_params["num_lobes"] = live_params.get("num_lobes", 3)
            common_params["radius"] = live_params.get("radius", 25)
        TYPE.HOURGLASS:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.HOURGLASS
            common_params["width"] = live_params.get("width", 50.0)
            common_params["height"] = live_params.get("height", 50.0)
            common_params["notch_width"] = live_params.get("notch_width", 25.0)
            common_params["bottom_displ"] = live_params.get("bottom_displ", Vector2.ZERO)
            common_params["top_displ"] = live_params.get("top_displ", Vector2.ZERO)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.DIAMOND:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.DIAMOND
            common_params["width"] = live_params.get("width", 50.0)
            common_params["height"] = live_params.get("height", 50.0)
            common_params["bottom_displ"] = live_params.get("bottom_displ", Vector2.ZERO)
            common_params["top_displ"] = live_params.get("top_displ", Vector2.ZERO)
            common_params["scale"] = live_params.get("scale", Vector2.ONE)
            common_params["skew"] = live_params.get("skew", 0.0)
        TYPE.SPIKE:
            common_params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.SPIKE
            common_params["base_width"] = live_params.get("base_width", 50.0)
            common_params["base_height"] = live_params.get("base_height", 25.0)
            common_params["spike_height"] = live_params.get("spike_height", 25.0)
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
            
    eye_shape_params = common_params.duplicate()
    outline_shape_params = common_params.duplicate()
    
    # Distinguish outline shape's params
    outline_shape_params["filled"] = false
    outline_shape_params["outline_width"] = outline_width * 2 # Half width is covered by body
    outline_shape_params["color"] = outline_color
            
    return [eye_shape_params, outline_shape_params]
    
func _draw():
    if draw_eye and is_instance_valid(eye_shape_logic): eye_shape_logic.draw_on(self)

## --- Eyelids ---
func get_child_eyelids() -> Array:
    var children = get_children()
    var found_eyelids: Array = []
    for child in children:
        if child is BaseCreatureEyelids:
            found_eyelids.append(child)
    return found_eyelids
    
# --- Eyelid Handling ---
func handle_eyelids():
    var existing_eyelids = get_child_eyelids()
    
    if not has_eyelids:
        for lid in existing_eyelids: lid.queue_free()
        return
            
    var lids: BaseCreatureEyelids
    if existing_eyelids.is_empty():
        lids = BaseCreatureEyelids.new()
        add_child(lids)
    else:
        lids = existing_eyelids[0]

    lids.name = self.name + "_lids"
    
    # Pass the main eye's logic object directly to the eyelid.
    # The eyelid can now query this object for any data it needs.
    lids.configure(eye_shape_logic)
    
    # Pass the other necessary parameters
    lids.lid_behavior = _get_enum_names(LID_TYPE).get(lid_type).to_lower()
    lids.eyelid_color_top = eyelid_color_top
    lids.eyelid_color_bottom = eyelid_color_bottom
    lids.openness = master_openness
    
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

## --- Animation ---
 
# --- Blinking ---
func blink():
    if _blinking:
        return
        
    _blinking = true
    
    if is_instance_valid(_current_blink_tween) and _current_blink_tween.is_valid():
        _current_blink_tween.kill()
        _current_blink_tween = null
        
    # Create tween:
    _current_blink_tween = create_tween()
    
    match(blink_type):
        BLINK_TYPE.OPENNESS: 
            await openness_blink()
        BLINK_TYPE.SCALING: await scaling_blink()
        _: await openness_blink()
        
    blinked.emit()
    _blinking = false
    
func openness_blink():
    # Animate from current master_openness to 0.0 (closed) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "master_openness", 0.0, time_to_blink/2)
    
    # Add a delay (hold closed for 0.1 seconds):
    _current_blink_tween.tween_interval(hold_closed_time)
    
    # Animate from current current master_openness (0.0/closed) to 1.0 (open) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "master_openness", 1.0, time_to_blink/2)
    
    await _current_blink_tween.finished
    
func scaling_blink():
    # Create tween:
    _current_blink_tween = create_tween()
                
    # Animate from current master_openness to 0.0 (closed) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "scale", Vector2.ZERO, time_to_blink/2)
    
    # Add a delay (hold closed for 0.1 seconds):
    _current_blink_tween.tween_interval(hold_closed_time)
    
    # Animate from current current master_openness (0.0/closed) to 1.0 (open) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "scale", Vector2.ONE, time_to_blink/2)
    
    await _current_blink_tween.finished
    
func stop_blinking():
    _blinking = false
    
    if _current_blink_tween and _current_blink_tween.is_valid():
        _current_blink_tween.kill()
        _current_blink_tween = null
        
    blinked.emit(self)
    
func _on_blink_end():
    pass

# --- Override pulse() ---
func update_pulse_state():
    if not is_node_ready(): return

    if pulsing and blink_type != BLINK_TYPE.SCALING: # Scaling blink mode forbids pulsing
        _start_pulse()
    else:
        _stop_pulse()
