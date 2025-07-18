@tool
extends BlockPart

class_name BlockBody

var params: Dictionary:
    set(v):
        if params == v:
            return
            
        params = v
        if not is_node_ready():
            update_from_params(params)
        
var live_params: Dictionary
    
## --- Cached Vars --
var size: Vector2 = Vector2.ONE * Constants.tile_size
var shape_color: Color = Color.LIGHT_SLATE_GRAY
var shape_position := Vector2.ZERO
var shape_rotation := 0.0
var clip_child_parts: bool = true

## --- Internal State ---
var points_shape: PackedVector2Array

func _ready() -> void:
    update_from_params({}) # Use default vars
    
# NOTE: The central update function. It calculates and stores the state.
func update_from_params(new_params: Dictionary):
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    # Declare part type
    part_type = PART_TYPE.MAIN_BODY
    
    # Set params. Equal condition handled by setter.
    params = new_params
    
    # Update live params
    live_params = await get_live_values_of_dict(params)

    ## Update state variables from the dictionary
    size = live_params.get("size", size)
    shape_color = live_params.get("shape_color", shape_color)
    shape_position = live_params.get("shape_position", shape_position)
    shape_rotation = live_params.get("shape_rotation", shape_rotation)
    clip_child_parts = live_params.get("clip_child_parts", clip_child_parts)
    
    # Enforce clipping (or don't):
    if clip_child_parts: clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
    else: clip_child_parts = CanvasItem.CLIP_CHILDREN_DISABLED
    
    # Update the shape logic:
    update_shape_renderer()
    
func update_shape_renderer():
    # 1. Assemble the parameters for the body and outline's shapes.
    var shape_params = form_shape_params()
    var new_stack: Array[CustomShapeLogic] = []
    
    # 2. Create the logic objects.
    var shape = CustomShapeLogic.new(shape_params)
    new_stack.append(shape)
    
    # 3. Update the renderer's logic stack.
    logic_stack = new_stack
        
    # Update the point-holding vars:
    points_shape = shape.get_points()
        
# This function's only job is to create the correct params dictionary.
func form_shape_params() -> Dictionary:
    var body_shape_params: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
        "size": size,
        "color": shape_color,
        "position": shape_position,
        "rotation": shape_rotation
    }
            
    return body_shape_params
