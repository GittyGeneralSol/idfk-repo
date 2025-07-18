@tool

extends BaseCreaturePart

# class_name BaseCreatureEye

enum EYE_TYPE {
    POLYGON,
    CIRCLE,
    RECTANGLE,
    STAR
}

const EYE_TYPE_PREFIXES = {
    EYE_TYPE.POLYGON: "polygon_",
    EYE_TYPE.CIRCLE: "circ_",
    EYE_TYPE.RECTANGLE: "rect_",
    EYE_TYPE.STAR: "star_",
}

enum LID_TYPE {
    UNILID,
    TWOLID,
    OMNI,
    CIRCLE,
    RECTANGLE,
    TRIANGLE
}

# --- Customize these parameters ---
@export_group("Eye")
@export var eye_type: EYE_TYPE = EYE_TYPE.CIRCLE:
    set(new_value): eye_type = new_value; update_eye()
    
@export var eye_color: Color = Color.DEEP_PINK:
    set(new_value): eye_color = new_value; update_eye()
    
@export var has_eyelids: bool = true:
    set(new_value): has_eyelids = new_value; handle_eyelids()

@export var eyelids_type: LID_TYPE = LID_TYPE.TWOLID:
    set(new_value): eyelids_type = new_value; update_eye()
    
@export var eyelid_color_top: Color = Color.SKY_BLUE:
    set(new_value): eyelid_color_top = new_value; handle_eyelids()

@export var eyelid_color_bottom: Color = Color.SKY_BLUE:
    set(new_value): eyelid_color_bottom = new_value; handle_eyelids()
        
@export var shape_displacement: Vector2 = Vector2.ZERO: # Offset the eye's center
    set(new_value): shape_displacement = new_value; update_eye()
        
@export var shape_rotation: float = 0: # Rotate the eye
    set(new_value): shape_rotation = new_value; update_eye()
    
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
        
# --- Expose Custom Creature Body Properties ---
@export_subgroup("Read-Only Body Properties")
@export var eye_properties: Dictionary:
    set(new_value): pass

# --- Draw Bools ---
@export_subgroup("Draw Bools")
@export var draw_eye: bool = true:
    set(new_value):
        draw_eye = new_value
        queue_redraw()
        
# --- Shape-Specific Params ---
@export_group("Shape-Specific Params")
@export_subgroup("Polygon Parameters", "polygon_")
@export var polygon_circumrad: float = 35:
    set(new_value): polygon_circumrad = new_value; update_eye()
@export var polygon_num_points: int = 3:
    set(new_value): polygon_num_points = new_value; update_eye()
@export var polygon_snap_closest: bool = true:
    set(new_value): polygon_snap_closest = new_value; update_eye()
var polygon_properties: PackedStringArray = ["polygon_circumrad", "polygon_num_points", "polygon_snap_closest"]
    
@export_subgroup("Circle Parameters")
@export var circ_radius: float = 25.0:
    set(new_value): circ_radius = new_value; update_eye()
var circle_properties: PackedVector2Array = ["eye_radius"]

@export_subgroup("Rectangle Parameters")
@export var rect_size: Vector2 = Vector2(50, 50):
    set(new_value): rect_size = new_value; update_eye()

@export_subgroup("Star Parameters")
@export var star_num_points: int = 5:
    set(new_value): star_num_points = new_value; update_eye()
@export var star_outer_rad: float = 40.0:
    set(new_value): star_outer_rad = new_value; update_eye()
@export var star_inner_rad: float = 20.0:
    set(new_value): star_inner_rad = new_value; update_eye()

# --- Internal State ---
var eye_shape_logic: CustomShapeLogic
var eyelids_logic: CustomShapeLogic # We will also use this for eyelids
var _current_blink_tween: Tween


func _ready() -> void:
    clip_children = ClipChildrenMode.CLIP_CHILDREN_AND_DRAW
    update_eye()

# NOTE: Central Update function.
func update_eye():
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    part_type = PART_TYPE.EYE
    setup_eye_properties()
    _update_shape_logic()
    handle_eyelids() # This will also be updated to use the new pattern
    queue_redraw()
    update_pulse_state()

func get_child_eyelids() -> Array:
    var children = get_children()
    var found_eyelids: Array = []
    for child in children:
        if child is BaseCreatureEyelids:
            found_eyelids.append(child)
    return found_eyelids

func setup_eye_properties():
    setup_part_properties()
    eye_properties.clear()
    
    if procedurally_created:
        return
    
    var _eye_type_names: Dictionary = _get_enum_names(EYE_TYPE)
    eye_properties["eye_type"] = _eye_type_names.get(eye_type, "UNKNOWN")
    eye_properties["eye_color"] = { "r": eye_color.r, "g": eye_color.g, "b": eye_color.b, "a": eye_color.a }
    eye_properties["time_to_blink"] = time_to_blink
    eye_properties["hold_closed_time"] = hold_closed_time
    eye_properties["pulsing"] = pulsing
    eye_properties["spinning"] = spinning
    eye_properties["has_eyelids"] = has_eyelids
    eye_properties["eyelids_type"] = eyelids_type
    eye_properties["eyelid_color_top"] = { "r": eyelid_color_top.r, "g": eyelid_color_top.g, "b": eyelid_color_top.b, "a": eyelid_color_top.a }
    eye_properties["eyelid_color_bottom"] = { "r": eyelid_color_bottom.r, "g": eyelid_color_bottom.g, "b": eyelid_color_bottom.b, "a": eyelid_color_bottom.a }
    eye_properties["shape_displacement"] = { "x": shape_displacement.x, "y": shape_displacement.y }
    eye_properties["shape_rotation"] = shape_rotation
    
    var prefix = EYE_TYPE_PREFIXES.get(eye_type, "")
    var all_properties: Array[Dictionary] = get_property_list()
    var shape_properties: Dictionary
    
    for prop_info in all_properties:
        var prop_name: String = prop_info["name"]
        
        # Check if the property name starts with our desired prefix.
        if prop_name.begins_with(prefix):
            var name_without_prefix = prop_name.trim_prefix(prefix)
            if get(prop_name) is not Vector2:  
                shape_properties[name_without_prefix] = get(prop_name)
            else:
                var value: Vector2 = get(prop_name)
                shape_properties[name_without_prefix] = { "x": value.x, "y": value.y }
    
    eye_properties["shape_properties"] = shape_properties
    part_properties["eye_properties"] = eye_properties

func _update_shape_logic():
    # 1. Assemble the parameters for the main eye shape.
    var params = _get_eye_shape_params()
    
    # 2. Create/update the logic object.
    if not is_instance_valid(eye_shape_logic):
        eye_shape_logic = CustomShapeLogic.new(params)
    else:
        eye_shape_logic.update_from_params(params)

# This function's only job is to create the correct params dictionary.
func _get_eye_shape_params() -> Dictionary:
    # Universal properties
    var params = {
        "color": eye_color,
        "position": shape_displacement,
        "rotation": shape_rotation
    }
    
    # Shape-specific properties
    match eye_type:
        EYE_TYPE.POLYGON:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.POLYGON
            params["num_points"] = polygon_num_points
            params["radius"] = polygon_circumrad
        EYE_TYPE.CIRCLE:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.CIRCLE
            params["radius"] = circ_radius
        EYE_TYPE.RECTANGLE:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.RECTANGLE
            params["size"] = rect_size
        EYE_TYPE.STAR:
            params["shape_type"] = CustomShapeLogic.SHAPE_TYPE.STAR
            params["num_points"] = star_num_points
            params["outer_radius"] = star_outer_rad
            params["inner_radius"] = star_inner_rad
            
    return params
           
# Standard draw(), override this
func _draw():
    if not draw_eye or not is_instance_valid(eye_shape_logic):
        return
    
    # The draw call is now incredibly simple.
    eye_shape_logic.draw_on(self)
                
# --- Blinking ---
func blink():
    # Kill any existing tween managed by this script
    if _current_blink_tween and _current_blink_tween.is_valid():
        _current_blink_tween.kill()
        
    # Create tween:
    _current_blink_tween = create_tween()
                
    # Animate from current master_openness to 0.0 (closed) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "master_openness", 0.0, time_to_blink/2)
    
    # Add a delay (hold closed for 0.1 seconds):
    _current_blink_tween.tween_interval(hold_closed_time)
    
    # Animate from current current master_openness (0.0/closed) to 1.0 (open) over a period of 0.1 seconds:
    _current_blink_tween.tween_property(self, "master_openness", 1.0, time_to_blink/2)
    
    await _current_blink_tween.finished
    
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
    lids.lid_behavior = _get_enum_names(LID_TYPE).get(eyelids_type).to_lower()
    lids.eyelid_color_top = eyelid_color_top
    lids.eyelid_color_bottom = eyelid_color_bottom
    lids.openness = master_openness
