@tool
extends BaseCreaturePart
class_name BaseCreatureDeco

### --- Main Data Objects ---
# Master Input: SHAPE_STACK (AKA: PARAMS_STACK)
var shape_stack: Array:
    set(v):
        if shape_stack == v:
            return
        
        shape_stack = v
        for params in shape_stack:
            live_stack.append(await get_live_values_of_dict(params))
        update_deco()
        
var live_stack: Array[Dictionary]

### --- Others ---
        
# --- Expose Custom Creature Body Properties ---
var deco_properties: Dictionary

# --- Store Data ---
var _logic_stack: Array[CustomShapeLogic]
var _points_stack: Array[PackedVector2Array] = []

func _ready():
    update_deco()

# NOTE: Central Update function.
func update_deco():
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    part_type = PART_TYPE.DECO
    setup_deco_properties()
    _update_shape_logics()
    
    
func setup_deco_properties():
    setup_part_properties()
    deco_properties.clear()
    
    if procedurally_created:
        return
    
    if not shape_stack.is_empty():
        for i in range(shape_stack.size()):     
            var shape_params = shape_stack[i]
            
            # Turn values of keys into dictionaries if required
            var _shape_type_names: Dictionary = _get_enum_names(CustomShapeLogic.SHAPE_TYPE)
            var shape_type = shape_params.get("shape_type", CustomShapeLogic.SHAPE_TYPE.CIRCLE)
            var shape_params_temp: Dictionary
            for key in shape_params.keys():
                var value = shape_params[key]
                if value is Vector2:
                    shape_params_temp[key] = { "x": value.x, "y": value.y }
                elif value is Color:
                    shape_params_temp[key] = { "r": value.r, "g": value.g, "b": value.b, "a": value.a }
                else:
                    shape_params_temp[key] = value
            shape_params_temp["shape_type"] = _shape_type_names.get(shape_type, "UNKNOWN")
            
            deco_properties["shape_" + str(i)] =  shape_params_temp    
    part_properties["deco_properties"] = deco_properties

func _draw():
    if _logic_stack.is_empty(): return

    for shape_logic in _logic_stack:
        shape_logic.draw_on(self)

func _update_shape_logics():
    _rebuild_logic_n_points_stack()
    queue_redraw()

func _rebuild_logic_n_points_stack():
    # Build logic:
    _logic_stack.clear()
    
    for params in live_stack:
        var shape_logic = CustomShapeLogic.new(params)
        _logic_stack.append(shape_logic)
    
    _points_stack.clear()
    
    # Build points:
    if _logic_stack.is_empty(): return

    for shape_logic in _logic_stack:
        _points_stack.append(shape_logic.get_points())
