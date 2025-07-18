@tool

extends BaseCreaturePart

# class_name BaseCreatureMainBody

enum BODY_TYPE {
    CIRCLE, RECTANGLE, POLYGON, STAR, REULEAUX, HYPOCYCLOID, IRREGULAR
}

const BODY_TYPE_PREFIXES = {
    BODY_TYPE.CIRCLE: "circ_",
    BODY_TYPE.RECTANGLE: "rect_",
    BODY_TYPE.POLYGON: "polygon_",
    BODY_TYPE.STAR: "star_",
    BODY_TYPE.REULEAUX: "reuleaux_",
    BODY_TYPE.HYPOCYCLOID: "hypo_",
    BODY_TYPE.IRREGULAR: "irregular_"
}

# --- Customize these parameters ---
@onready var body_params: Dictionary:
    set(v): body_params = v; update_body()

@export_group("Body")
@export var body_type: BODY_TYPE = BODY_TYPE.POLYGON:
    set(new_value): body_type = new_value; update_body()
        
# Use polyline() instead of polygon() for outlines
@export var use_polyline: bool = true:
    set(new_value): use_polyline = new_value; update_body()
        
@export var outline_width: float = 10.0:
    set(new_value): outline_width = new_value; update_body()
        
@export var outline_correction: float = -3.0:
    set(new_value): outline_correction = new_value; update_body()
    
@export var body_color: Color = Color.DEEP_PINK:
    set(new_value): body_color = new_value; queue_redraw()
        
@export var shape_displacement: Vector2 = Vector2.ZERO: # Offset the shape's center
    set(new_value): shape_displacement = new_value; update_body()
        
@export var shape_rotation: float = -90: # Rotate the body
    set(new_value): shape_rotation = new_value; update_body()
        
# --- Expose Custom Creature Body Properties ---
@export_subgroup("Read-Only Body Properties")
@export var body_properties: Dictionary:
    set(new_value): pass

# --- Draw Bools ---
@export_subgroup("Draw Bools")
@export var draw_body: bool = true:
    set(new_value):
        draw_body = new_value
        queue_redraw()
@export var draw_outline: bool = true:
    set(new_value):
        draw_outline = new_value
        queue_redraw()
        
# --- Shape-Specific Params ---
@export_group("Shape-Specific Params")
@export_subgroup("Polygon Parameters", "polygon_")
@export var polygon_circumrad: float = 90:
    set(new_value): polygon_circumrad = new_value; update_body()
@export var polygon_num_points: int = 3:
    set(new_value): polygon_num_points = new_value; update_body()
@export var polygon_snap_closest: bool = true:
    set(new_value): polygon_snap_closest = new_value; update_body()

@export_subgroup("Circle Parameters", "circ_")
@export var circ_radius: float = 90:
    set(new_value): circ_radius = new_value; update_body()

@export_subgroup("Rectangle Parameters", "rect_")
@export var rect_size: Vector2 = Vector2(150, 150):
    set(new_value): rect_size = new_value; update_body()

@export_subgroup("Star Parameters", "star_")
@export var star_num_points: int = 5:
    set(new_value): star_num_points = new_value; update_body()
@export var star_outer_rad: float = 40.0:
    set(new_value): star_outer_rad = new_value; update_body()
@export var star_inner_rad: float = 20.0:
    set(new_value): star_inner_rad = new_value; update_body()
    
@export_subgroup("Reuleaux Parameters", "reuleaux_")
@export var reuleaux_num_lobes: int = 3:
    set(new_value): reuleaux_num_lobes = new_value; update_body()
@export var reuleaux_circumrad: float = 90:
    set(new_value): reuleaux_circumrad = new_value; update_body()
    
@export_subgroup("Hypocycloid Parameters", "hypo_")
@export var hypo_num_lobes: int = 3:
    set(new_value): hypo_num_lobes = new_value; update_body()

# --- Store Generated Data ---
var points_body: PackedVector2Array
var points_outline: PackedVector2Array

# --- Internal State ---
var body_shape_logic: CustomShapeLogic
var outline_shape_logic: CustomShapeLogic

func _ready() -> void:
    update_body()
    
func update_from_dict():
    for param in body_params.keys():
        var value = body_params.get(param)
        self.set(param, body_params[param])

# NOTE: Central Update function.
func update_body():
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    part_type = PART_TYPE.MAIN_BODY
    setup_body_properties()
    _update_shape_logic()
    
    points_body = body_shape_logic.get_points()
    points_outline = outline_shape_logic.get_points()
    
    queue_redraw()

func setup_body_properties():
    setup_part_properties()
    body_properties.clear()
    
    if procedurally_created:
        return
    
    var _body_type_names: Dictionary = _get_enum_names(BODY_TYPE)
    # Prioritize enum value from body_params, fall back to the exported var.
    var final_body_type_enum = body_params.get("body_type", body_type)
    body_properties["body_type"] = _body_type_names.get(final_body_type_enum, "UNKNOWN")
    
    # 2. Universal Booleans and Floats
    body_properties["use_polyline"] = body_params.get("use_polyline", use_polyline)
    body_properties["outline_width"] = body_params.get("outline_width", outline_width)
    body_properties["outline_correction"] = body_params.get("outline_correction", outline_correction)
    body_properties["shape_rotation"] = body_params.get("shape_rotation", shape_rotation)

    # 3. Handle Complex Types (Color and Vector2)
    # These need to be converted to serializable dictionaries if they are objects.
    var final_color = body_params.get("body_color", body_color)
    if final_color is Color:
        body_properties["body_color"] = { "r": final_color.r, "g": final_color.g, "b": final_color.b, "a": final_color.a }
    else: # If it's not a Color, assume it's already a valid dictionary from body_params
        body_properties["body_color"] = final_color

    var final_displacement = body_params.get("shape_displacement", shape_displacement)
    if final_displacement is Vector2:
        body_properties["shape_displacement"] = { "x": final_displacement.x, "y": final_displacement.y }
    else: # Assume it's already a valid dictionary
        body_properties["shape_displacement"] = final_displacement
        
    # --- SHAPE-SPECIFIC PROPERTIES ---
    # Check if body_params provides a complete "shape_properties" dictionary.
    # If so, we use it directly. If not, we build it from the script's export vars.
    if body_params.has("shape_properties"):
        # Priority: Use the dictionary provided in body_params directly.
        body_properties["shape_properties"] = body_params.get("shape_properties")
    else:
        # Fallback: Build the dictionary by inspecting the script's properties.
        var shape_properties: Dictionary
        var prefix = BODY_TYPE_PREFIXES.get(final_body_type_enum, "")
        var all_properties: Array[Dictionary] = get_property_list()
        
        for prop_info in all_properties:
            var prop_name: String = prop_info["name"]
            
            if prop_name.begins_with(prefix):
                var name_without_prefix = prop_name.trim_prefix(prefix)
                var value = get(prop_name)
                
                if value is Vector2:
                    shape_properties[name_without_prefix] = { "x": value.x, "y": value.y }
                else:
                    shape_properties[name_without_prefix] = value
                    
        body_properties["shape_properties"] = shape_properties
        
    part_properties["body_properties"] = body_properties

func _update_shape_logic():
    # 1. Assemble the parameters for the main body shape.
    var all_params = _get_body_shape_params()
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

# This function's only job is to create the correct params dictionary.
func _get_body_shape_params() -> Array[Dictionary]:
    var body_shape_params: Dictionary
    var outline_shape_params: Dictionary
    
    # Universal properties
    var params = {
        "color": body_params.get("body_color", body_color),
        "position": body_params.get("shape_displacement", shape_displacement),
        "rotation": body_params.get("shape_rotation", shape_rotation)
    }
    
    var shape_params = body_params.get("shape_params", {})
    var final_body_type = body_params.get("body_type", body_type)
    print(body_params)
    
    if not final_body_type:
        printerr("FATAL ERROR")
        return []
    
    # Shape-specific properties
    match (final_body_type):
        BODY_TYPE.POLYGON:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.POLYGON
            params["num_points"] = shape_params.get("num_points", polygon_num_points)
            params["radius"] = shape_params.get("radius", polygon_circumrad)
        BODY_TYPE.CIRCLE:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.CIRCLE
            params["radius"] = shape_params.get("radius", circ_radius)
        BODY_TYPE.RECTANGLE:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.RECTANGLE
            params["size"] = shape_params.get("size", rect_size)
        BODY_TYPE.STAR:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.STAR
            params["num_points"] = shape_params.get("num_points", star_num_points)
            params["outer_radius"] = shape_params.get("outer_radius", star_outer_rad)
            params["inner_radius"] = shape_params.get("inner_radius", star_inner_rad)
        BODY_TYPE.REULEAUX:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.REULEAUX
            params["num_lobes"] = shape_params.get("num_lobes", reuleaux_num_lobes)
            params["radius"] = shape_params.get("radius", reuleaux_circumrad)
            
    body_shape_params = params.duplicate()
    outline_shape_params = params.duplicate()
    outline_shape_params["filled"] = false
    outline_shape_params["width"] = outline_width
    outline_shape_params["color"] = Color.BLACK
            
    return [body_shape_params, outline_shape_params]
    
# Standard draw(), override this
func _draw():
    if draw_body and is_instance_valid(body_shape_logic): body_shape_logic.draw_on(self)
    if draw_outline and is_instance_valid(outline_shape_logic): outline_shape_logic.draw_on(self)
        
func get_active_prop(prop_name: String) -> Variant:
    var found_value: Variant = super.get_active_prop(prop_name)
    
    # Regular case
    if found_value:
        return found_value
    
    if not prop_name.contains("active_"):
        return found_value
        
    match(prop_name):
        "active_circumrad":
            return get_active_circumrad()
    return

func get_active_circumrad():
    match(body_type):
        BODY_TYPE.CIRCLE:
            return circ_radius
        BODY_TYPE.POLYGON:
            return polygon_circumrad
        BODY_TYPE.REULEAUX:
            return reuleaux_circumrad
