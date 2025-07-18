@tool

extends BaseCreaturePart

# class_name BaseCreatureEyeContainer

enum CLUSTER_TYPE {
    RING
}

const CLUSTER_TYPE_PREFIXES = {
    CLUSTER_TYPE.RING: "ring_",
}

@export_group("Eye Cluster")
var num_eyes: int = 0:
    set(v):
        if num_eyes == v:
            return
            
        num_eyes = v
        update_eye_container()
        
@export var cluster_type: CLUSTER_TYPE = CLUSTER_TYPE.RING:
    set(v): cluster_type = v; update_eye_container()
@export var cluster_params: Dictionary = {}:
    set(v): 
        if cluster_params == v:
            return
            
        cluster_params = v
        live_cluster_params = await get_live_values_of_dict(cluster_params)
        update_eye_container()
        
@export var eye_params: Dictionary:
    set(v): 
        if eye_params == v:
            return
            
        eye_params = v
        live_eye_params = await get_live_values_of_dict(eye_params)
        update_eye_container()

var live_cluster_params: Dictionary
var live_eye_params: Dictionary

@export_group("Animation")
@export var rotational_anchor: Node2D:
    set(v): rotational_anchor = v; update_eye_container()
@export var rotational_anchor_offset: float = 0.0:
    set(v): rotational_anchor_offset = v; update_eye_container()
@export var follows_anchor_rotation: bool = true:
    set(v): follows_anchor_rotation = v; update_eye_container()

# --- Customize these parameters ---
@export_group("Eyelid Control")
@export_range(0.0, 1.0, 0.01) var master_openness = 1.0:
    set(new_value):
        master_openness = new_value
        var children = get_eyeish_children()
        for child in children:
            child.master_openness = master_openness
    get():
        return master_openness
        
# --- Expose Custom Creature Body Properties ---
var container_properties: Dictionary

# --- Internal ---
var child_eyes: Array:
    set(new_value): pass
    get(): child_eyes = get_eyeish_children(); return child_eyes
var created_eyes: Array
var _blink_timer: SceneTreeTimer
    
func _physics_process(_delta: float) -> void:
    if rotational_anchor:
        follow_rotational_anchor()
        return
    
    # Spin only if no anchor
    spin()
        
# NOTE: Central Update function.
func update_eye_container():
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    part_type = PART_TYPE.EYE_CONTAINER
    setup_container_properties()
    
    # Cache data:
    num_eyes = live_cluster_params.get("num_eyes", 0)
    rotational_anchor = live_cluster_params.get("rotational_anchor", null)
    rotational_anchor_offset = live_cluster_params.get("rotational_anchor_offset", 0.0)
    
    # Create the eye cluster, if configured.
    if num_eyes > 0:
        create_eye_cluster(num_eyes, cluster_type, live_cluster_params, live_eye_params)
    
    # Start the animations if configured.
    _update_animation_state()
    
func get_eyeish_children() -> Array:
    var children = get_children()
    var found_eyeish: Array = []
    for child in children:
        if child is BaseCreatureEye or child is BaseCreatureEyeContainer:
            found_eyeish.append(child)
    return found_eyeish
    
func setup_container_properties():
    setup_part_properties()
    container_properties.clear()
    
    if procedurally_created:
        return
    
    container_properties["part_position"] = { "x": position.x, "y": position.y }
    container_properties["part_rotation"] = rotation_degrees
    
    if is_instance_valid(rotational_anchor):
        container_properties["rotational_anchor"] = rotational_anchor.name
        container_properties["rotational_anchor_offset"] = rotational_anchor_offset
    
    var _cluster_type_names: Dictionary = _get_enum_names(CLUSTER_TYPE)
    if num_eyes > 0:
        var eye_cluster_props: Dictionary = {
            "num_eyes": num_eyes,
            "cluster_type": _cluster_type_names.get(cluster_type, "")
        }
        
        # Turn values of keys into dictionaries if required
        var eye_params_temp: Dictionary
        for key in eye_params.keys():
            var value = eye_params[key]
            if value is Vector2:
                eye_params_temp[key] = { "x": value.x, "y": value.y }
            elif value is Color:
                eye_params_temp[key] = { "r": value.r, "g": value.g, "b": value.b, "a": value.a }
            else:
                eye_params_temp[key] = value
        
        eye_cluster_props["cluster_type_params"] = cluster_params
        eye_cluster_props["eye_params"] = eye_params_temp
        container_properties["eye_cluster_properties"] = eye_cluster_props
        
    part_properties["container_properties"] = container_properties
    
## --- Animation ---

func follow_rotational_anchor():
     if follows_anchor_rotation and is_instance_valid(rotational_anchor):
        rotation_degrees = fmod(rotational_anchor.rotation_degrees + rotational_anchor_offset, 360)

func _update_animation_state():
    if not is_node_ready(): return

    if pulsing:
        _start_pulse()
    else:
        _stop_pulse()

func _start_pulse():
    if _pulse_tween and _pulse_tween.is_valid():
        _pulse_tween.kill()
        
    _pulse_tween = create_tween().set_loops()
    _pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_SINE)
    _pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)

func _stop_pulse():
    if _pulse_tween and _pulse_tween.is_valid():
        _pulse_tween.kill()
    
    var return_tween = create_tween()
    return_tween.tween_property(self, "scale", Vector2.ONE, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
            
    
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
    
    # Applying params
    add_child(eye)
    eye.params = params
    created_eyes.append(eye)
    print("create_eye has been reached. Params: ", params)
    return eye
    
func create_eye_cluster(count: int, cluster_type: CLUSTER_TYPE = CLUSTER_TYPE.RING, live_cluster_params: Dictionary = {}, live_eye_params: Dictionary = {}) -> Array:
    # DANGER: Clear the previously generated eyess
    clear_created_eyes()
    print("create_eye_cluster has been reached.")
    
    # Create the necessary eye cluster.
    var eyes: Array
    match(cluster_type):
        0: eyes = create_eye_ring(count, live_cluster_params.get("ring_radius", 50.0), live_eye_params)
        _: pass
    
    return eyes
    
func create_eye_ring(count: int, ring_radius: float = 50.0, live_eye_params: Dictionary = {}) -> Array[BaseCreatureEye]:
    print("create_eye_cluster has been reached. ")
    
    var eyes: Array[BaseCreatureEye]
    if count <= 0: print("if count <= 0 returned true."); return eyes
    
    print("if count <= 0 has been passed.")
    
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
        var final_params = live_eye_params.duplicate()
        
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
    
# --- Blinking ---

func blink():
    for child in get_eyeish_children():
        await child.blink()

        
