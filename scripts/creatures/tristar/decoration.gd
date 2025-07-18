@tool
extends BaseCreatureDeco

@export_group("Triangle Configuration")
@export var triangle_size: float = 20.0:
    set(v): triangle_size = v; _generate_deco()
@export var base_positions: PackedVector2Array:
    set(v): base_positions = v; _generate_deco()

@export_group("Appearance")
@export var color1: Color = Color.DODGER_BLUE:
    set(v): color1 = v; _generate_deco()
@export var color2: Color = Color.DEEP_SKY_BLUE:
    set(v): color2 = v; _generate_deco()
@export var color3: Color = Color.STEEL_BLUE:
    set(v): color3 = v; _generate_deco()


func _ready():
    _generate_deco()

# This is the single "brain" function for this object.
func _generate_deco():
    if not is_node_ready():
        call_deferred("_generate_deco")
        return

    # Safety check: Ensure we have the 3 base positions we need.
    if base_positions.size() < 3:
        shape_stack.clear() # Clear any old shapes
        queue_redraw()
        return

    # --- Calculations (taken directly from your original _draw function) ---
    var R = triangle_size
    var pos_v_offset = R / 2.0
    var pos_h_offset = sqrt(R*R - pos_v_offset*pos_v_offset)

    # --- Position the three triangles ---
    var pos_top = base_positions[0] + Vector2(0, R)
    var pos_right = base_positions[1] + Vector2(-pos_h_offset, -pos_v_offset)
    var pos_left = base_positions[2] + Vector2(pos_h_offset, -pos_v_offset)

    # --- Build the shape_params for each triangle ---
    var tri_top_params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "num_points": 3,
        "radius": triangle_size,
        "position": pos_top,
        "rotation": 150.0,
        "color": color1
    }
    
    var tri_right_params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "num_points": 3,
        "radius": triangle_size,
        "position": pos_right,
        "rotation": 150.0,
        "color": color2
    }
    
    var tri_left_params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "num_points": 3,
        "radius": triangle_size,
        "position": pos_left,
        "rotation": 150.0,
        "color": color3
    }
    
    # --- Assign the final array to the shape_stack ---
    # This will trigger the MultiCustomShape to redraw itself.
    self.shape_stack = [tri_top_params, tri_right_params, tri_left_params]
