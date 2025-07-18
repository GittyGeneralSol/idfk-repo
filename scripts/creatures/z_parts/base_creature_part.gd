@tool

extends Node2D

class_name BaseCreaturePart

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")
const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")
const HypocycloidGenerator = preload("res://scripts/shape_generators/HypocycloidGenerator.gd")

enum PART_TYPE {
    MAIN_BODY,
    DECO,
    EYE,
    EYELID,
    EYE_CONTAINER,
    OTHER
}

# --- Customize these parameters ---        
@export var part_type: PART_TYPE = PART_TYPE.MAIN_BODY:
    set(new_value): part_type = new_value; update_part()
    
## --- Animation ---   
@export_group("Animation")
@export var pulsing: bool = false:
    set(v): pulsing = v; update_pulse_state()
@export var spinning: bool = false:
    set(v): spinning = v

# --- Expose Custom Creature Body Properties ---
@export var part_properties: Dictionary

# --- Internal ---
@onready var procedurally_created: bool = false
var _pulse_tween: Tween

# For returning the names of enums
func _get_enum_names(enum_dict: Dictionary) -> Dictionary:
    var names = {}
    for key in enum_dict:
        var value = enum_dict[key]
        names[value] = key
    return names
    
func _process(_delta: float) -> void:
    spin()

# NOTE: Central Update function.
func update_part():
    if not is_node_ready():
        return # Don't do anything until the node and its children are ready
    
    setup_part_properties()
    queue_redraw()

func setup_part_properties():
    part_properties.clear()
    
    if procedurally_created:
        return
    
    var parent_part = get_parent().name
    if get_parent() == WorldUtils.get_parent_creature(self):
        parent_part = null
    
    var _part_type_names: Dictionary = _get_enum_names(PART_TYPE)
    part_properties["parent_part"] = parent_part
    part_properties["part_type"] = _part_type_names.get(part_type, "UNKNOWN")
    part_properties["part_position"] = { "x": position.x, "y": position.y }
    part_properties["part_rotation"] = rotation_degrees
    part_properties["spinning"] = spinning
    part_properties["pulsing"] = pulsing

# Modified get_parent_creature(). This may wait for self to be added in tree.
func get_parent_creature(obj: Node) -> Node:
    # 1. Safety check.
    if not is_instance_valid(obj):
        return null

    # 2. Get the owner of the scene this node belongs to.
    var scene_owner = obj.owner

    # 3. Check if the owner is valid and is the type we expect.
    if is_instance_valid(scene_owner) and scene_owner is BaseCreature:
        return scene_owner
    else:
        # Fallback to the loop ONLY if owner fails (e.g., for dynamically added nodes)
        # This part of the code is unlikely to be needed for your static scene.
        var current_node: Node = obj.get_parent()
        while current_node != null:
            if current_node is BaseCreature:
                return current_node
            current_node = current_node.get_parent()

    printerr("Could not find BaseCreature root for ", obj.name)
    return null
    
## --- Property Search ---
# Gets a property value using a path string like "body/circumrad"
func get_property_by_path(path: String, caller: Node = null) -> Variant:
    # Get the creature root first.
    var root_node = await get_parent_creature(self)
    if not is_instance_valid(root_node):
        printerr("Path failed: Could not find creature root from part '", self.name, "'.")
        return null
        
    # Check if a property is requested or a part:
    var valid_path: bool = false
    if path.contains("PROP-/"): # If is property
        path = path.lstrip("PROP-/")
        valid_path = true
    if path.contains("PART-/"): # If is part
        path = path.lstrip("PART-/")
        var part: BaseCreaturePart = get_part_by_name(path)
        if not is_instance_valid(part):
            printerr("Path failed: Part '", path, "' not found.")
            return null
        return part
        
    if not valid_path:
        printerr("Path failed: It is unspecified if path leads to a value or a part/node. Given path: ", path)
        return null

        
    var path_segments = path.split("/")
    
    # Start the search from the found root_node.
    var result = await _recursive_get_property(root_node, path_segments)
    if result is String:
        printerr("FATAL ERROR - (get_property_by_path) - The requested value with path '", path ,"' returned as banned type 'STRING'! Called by: ", caller)
        return
        
    return result

# Gets a direct reference to a part node using its path.
func get_part_by_name(part_path: String) -> Node:
    # Get the creature root first.
    var root_node = WorldUtils.get_parent_creature(self)
    if not is_instance_valid(root_node):
        printerr("Path failed: Could not find creature root from part '", self.name, "'.")
        return null
        
    return root_node.get_node_or_null(part_path)


# -- Private Helper Function --

func _recursive_get_property(current_node: Node, path_segments: Array) -> Variant:      
    # Get the next part of the path.
    var current_segment = path_segments[0]
    
    if current_segment.is_empty(): # Handles cases like "a//b"
        return await _recursive_get_property(current_node, path_segments.slice(1))

    # If this is the last segment, it's the property name.
    if path_segments.size() == 1:
        if not current_node.is_node_ready():
            await current_node.ready
        
        if current_node.has_method("get_active_prop"):
            return current_node.get_active_prop(current_segment)
        else:
            return current_node.get(current_segment)
    
    # If this is the second last segment, it might be a dictionary access.   
    if path_segments.size() == 2:
        var potential_dict_name = path_segments[0] # e.g., "params"
        var key_in_dict = path_segments[1]         # e.g., "body_type"

        # Check if the node *has* a property with that name.
        if potential_dict_name in current_node:
            if not current_node.is_node_ready():
                await current_node.ready
            
            # Get the actual property's value.
            var property_value = current_node.get(potential_dict_name)

            # NOW, check if that VALUE is a dictionary.
            if property_value is Dictionary:
                # If it is, look up the key INSIDE THE DICTIONARY.
                return property_value.get(key_in_dict) 

    #If the dictionary check failed or didn't run, continue to node traversal. It's a child node name. Find it.
    var child_node = current_node.get_node_or_null(current_segment)

    if not is_instance_valid(child_node):
        printerr("Path failed: Could not find child '", current_segment, "' on node '", current_node.name, "'")
        return null
        
    # Recurse with the child node and the rest of the path.
    return await _recursive_get_property(child_node, path_segments.slice(1))
    
func get_live_values_of_dict(dict: Dictionary) -> Dictionary:
    var new_dict = dict.duplicate()
    for prop in new_dict:
        var val = new_dict.get(prop)
        if not (val is String):
            continue # Skip
        if val.contains("PROP-/") or val.contains("PART-/"): # If is property or part
            new_dict[prop] = await get_property_by_path(val, self)
    return new_dict

## --- Custom Active Properties. Do Override ---
func get_active_prop(prop_name: String) -> Variant:
    var found_value: Variant
    
    found_value = get(prop_name)
    return found_value
    
## --- Animation ---
func spin():
    if spinning:
        rotation_degrees = fmod(rotation_degrees + 1, 360)

func update_pulse_state():
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
    
func _cane_swing_anim():
    var _animator = self._animator
    
    if not is_instance_valid(_animator):
        return
    
    var path = _animator.get_path_to(self)
    var animation = Animation.new()
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track_index, "rotation")
    animation.track_insert_key(track_index, 0.0, 0)
    animation.track_insert_key(track_index, 2.0, 100)
    animation.length = 2.0
