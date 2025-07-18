@tool

extends BaseCreaturePart

class_name BaseCreatureEyeContainer

enum CLUSTER_TYPE {
    RING, IRREGULAR
}

### --- Main Data Objects ---
var cluster_params: Dictionary:
    set(v):
        if cluster_params == v:
            return
            
        cluster_params = v
        if is_node_ready():
            update_from_params(cluster_params)
        
var live_cluster_params: Dictionary
var eye_params: Dictionary
var live_eye_params: Dictionary

# --- Cached Vars --
var cluster_type: CLUSTER_TYPE = CLUSTER_TYPE.RING
var num_eyes: int = 0
var blink_delay: float = 0.0 # the delay b/w eyes blinking
var rotational_anchor: BaseCreaturePart
var rotational_anchor_offset: float = 0.0
var follows_anchor_rotation: bool = true

## --- Internal State ---
var container_properties: Dictionary
var created_eyes: Array[BaseCreatureEye]
var _blinking: bool = false
var _children_left_to_blink

## --- Control ---
@export_subgroup("Eyelid Control")
@export_range(0.0, 1.0, 0.01) var master_openness = 1.0:
    set(new_value):
        if new_value is not float:
            return
        
        master_openness = new_value
        for child in get_eyeish_children():
            child.master_openness = master_openness
    get:
        return master_openness
        
# --- Signals ---:
signal blinked()

# The constructor. Called when you do .new()
func _init(new_params: Dictionary = {}):
    cluster_params = new_params
    
func _ready() -> void:
    update_from_params(cluster_params)
    
func _physics_process(_delta: float) -> void:
    if rotational_anchor:
        follow_rotational_anchor()
        return
    
    # Spin only if no anchor
    spin()
    
# NOTE: The central update function. It calculates and stores the state.
func update_from_params(new_params: Dictionary):
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    # Declare part type
    part_type = PART_TYPE.EYE_CONTAINER
    
    # Handle connections:
    handle_connections()
        
    if self.cluster_params.is_empty():
        clear_created_eyes()
        live_cluster_params.clear()
        eye_params.clear()
        live_eye_params.clear()
        return
        
    # Update live params:
    eye_params = cluster_params.get("eye_params", {})
    live_eye_params = await get_live_values_of_dict(eye_params)
    live_cluster_params = await get_live_values_of_dict(cluster_params)

    ## Update state variables from the dictionary
    cluster_type = live_cluster_params.get("cluster_type", CLUSTER_TYPE.RING)
    num_eyes =  live_cluster_params.get("num_eyes", 0)
    blink_delay = live_cluster_params.get("blink_delay", 0.0)
    rotational_anchor = live_cluster_params.get("rotational_anchor", null)
    rotational_anchor_offset = live_cluster_params.get("rotational_anchor_offset", 0.0)
    
    # Setting up properties:
    setup_container_properties()
    
    # Handle the eye cluster:
    handle_eye_cluster()
    
func handle_connections():
    # Handle connections:
    if not blinked.is_connected(_on_blink_end):
        blinked.connect(_on_blink_end)
    
func setup_container_properties():
    setup_part_properties()
    container_properties.clear()
    
    if procedurally_created:
        return
    
    var temp_params = cluster_params.duplicate()
    var _cluster_type_names: Dictionary = _get_enum_names(CLUSTER_TYPE)
    
    # Save Body_Type first
    container_properties["cluster_type"] = _cluster_type_names.get(cluster_type, "UNKNOWN")
    temp_params.erase("cluster_type")
    
    container_properties.merge(save_props_by_type(temp_params, container_properties))
    
    part_properties["container_properties"] = container_properties
    
func handle_eye_cluster():
    # Create the eye cluster, if configured.
    if num_eyes > 0:
        create_eye_cluster(num_eyes, cluster_type, live_cluster_params, live_eye_params)
    else:
        clear_created_eyes()

## --- Eye Factory Functions ---
    
func create_eye(params: Dictionary) -> BaseCreatureEye:
    var eye: BaseCreatureEye = BaseCreatureEye.new()
    
    # Applying part properties
    eye.position = params.get("part_position", Vector2.ZERO)
    eye.rotation_degrees = params.get("part_rotation", 0.0)
    eye.pulsing = params.get("pulsing", false)
    eye.spinning = params.get("spinning", false)
    
    # Cleaning params to not include useless vars
    params.erase("part_position")
    params.erase("part_rotation")
    params.erase("pulsing")
    params.erase("spinning")
    
    # Naming the eye
    var num_eyes = created_eyes.size()
    eye.name = self.name + "_gen_eye_" + str(num_eyes + 1)
    
    # Applying params
    add_child(eye)
    eye.params = params
    created_eyes.append(eye)
    
    return eye
   
func create_eye_cluster(count: int, clust_type: CLUSTER_TYPE = CLUSTER_TYPE.RING, clust_props: Dictionary = {}, eye_props: Dictionary = {}) -> Array:
    # DANGER: Clear the previously generated eyess
    clear_created_eyes()
    
    # Create the necessary eye cluster.
    var eyes: Array
    match(clust_type):
        CLUSTER_TYPE.RING: eyes = create_eye_ring(count, clust_props.get("ring_radius", 50.0), eye_props)
        CLUSTER_TYPE.IRREGULAR: pass
        _: pass
    
    return eyes
    
func create_eye_ring(count: int, ring_radius: float = 50.0, eye_props: Dictionary = {}) -> Array[BaseCreatureEye]:
    var eyes: Array[BaseCreatureEye]
    if count <= 0: return eyes
    
    # Calculate the angle between each eye.
    var angle_step_rad = TAU / count

    for i in range(count):
        # 1. Calculate the angle for this eye's position on the ring.
        var position_angle_rad = i * angle_step_rad

        # 2. Calculate the position vector relative to the container's center.
        var eye_position = Vector2.RIGHT.rotated(position_angle_rad) * ring_radius
        
        # 3. Calculate the rotation to make the eye "point outwards".
        var eye_rotation_degrees = rad_to_deg(position_angle_rad)

        # 4. Prepare the parameters dictionary for this specific eye.
        # We start with the base parameters passed into the function...
        var final_params = eye_props.duplicate()
        
        # ...and then override the position and rotation with our calculated values.
        final_params["part_position"] = eye_position
        final_params["part_rotation"] = eye_rotation_degrees
        
        # 5. Create the eye using the factory function.
        var new_eye = create_eye(final_params)
        eyes.append(new_eye)
        
    return eyes
    
func clear_all_child_eyes() -> Array[BaseCreatureEye]:
    # DANGER: This function will annihilate ALL direct children eyes.
    
    var cleared_children: Array[BaseCreatureEye]
    for child in get_eyeish_children():
        if child is not BaseCreatureEyeContainer:
            cleared_children.append(child)
            child.queue_free()
    return cleared_children

func clear_created_eyes() -> Array[BaseCreatureEye]:
    # DANGER: Clear the previously generated eyes
    
    var deleted_successfully: Array[BaseCreatureEye]
    for eye in created_eyes:
        if is_instance_valid(eye):
            deleted_successfully.append(eye)
            eye.queue_free()
    created_eyes.clear()
    return deleted_successfully

## --- Animation ---
func follow_rotational_anchor():
     if follows_anchor_rotation and is_instance_valid(rotational_anchor):
        rotation_degrees = fmod(rotational_anchor.rotation_degrees + rotational_anchor_offset, 360)

## --- Utility ---
# --- Blinking ---
func blink():
    if _blinking: return # Prevent interruption
    
    _blinking = true
    
    var eyeish_children = get_eyeish_children()
    if eyeish_children.is_empty():
        # If there are no children, we are done immediately.
        blinked.emit()
        _blinking = false
        return
    
    # Count the number of children left
    _children_left_to_blink = eyeish_children.size()
    
    for child: BaseCreaturePart in eyeish_children:
        child.blinked.connect(Callable(self, "_on_child_blinked"), CONNECT_ONE_SHOT)
        if blink_delay > 0.0:
            await get_tree().create_timer(blink_delay).timeout
        child.blink()

# Blink completion handled by this helper
func _on_child_blinked():
    _children_left_to_blink -= 1
    # When the last child has blinked, emit the completion signal
    if _children_left_to_blink == 0:
        blinked.emit()
        _blinking = false
        
func stop_blinking():
    _blinking = false
    
    var eyeish_children = get_eyeish_children()
    if eyeish_children.is_empty():
        return
    for child in eyeish_children:
        if child.has_method("stop_blinking"):
            child.stop_blinking()
            
    blinked.emit(self)
    
func _on_blink_end():
    pass
        
func get_eyeish_children() -> Array:
    var children = get_children()
    var found_eyeish: Array = []
    for child in children:
        if child is BaseCreatureEye or child is BaseCreatureEyeContainer:
            found_eyeish.append(child)
    return found_eyeish
    
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
