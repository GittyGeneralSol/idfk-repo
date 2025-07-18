@tool

extends Block

@onready var object_container: Node = $ObjectContainer
@export var frozen_obj_path: String

func _ready() -> void:
    b_setup_variables("freeze_pod", _worldly_position, "freeze_pod_data")
    
    if frozen_obj_path:
        if frozen_obj_path.contains("worlds/"):
            printerr("Freeze Pod -  frozen_obj_path is ILLEGAL.")
            return
        
        _set_frozen_object()
    
func update_frozen_object():
    if frozen_obj_path.contains("worlds/"):
        printerr("Freeze Pod -  frozen_obj_path is ILLEGAL.")
        return
        
    update_stored_data()
    
    # Delete any pre-existing children
    if object_container.get_children():
        var children = object_container.get_children()
        for child in children:
            child.queue_free()
    
    # Wait 1 frame for previous object to get fully deleted
    await get_tree().process_frame    
    _set_frozen_object()

func _set_frozen_object():     
    update_stored_data()
    
    if frozen_obj_path and object_container.get_child_count() == 0:
        var OBJECT = load("res://scenes/" + frozen_obj_path + ".tscn")
        var current_obj = OBJECT.instantiate()
        current_obj.z_index = -15
        current_obj.scale = Vector2(0.5, 0.5)
        
        ## Check for properties
        if "pulsing_eye" in current_obj:
            current_obj.pulsing_eye = false
        if "rotating_eye" in current_obj:
            current_obj.rotating_eye = false
        if "is_frozen" in current_obj:
            current_obj.is_frozen = true
            
        object_container.add_child(current_obj)
        
func update_stored_data():
    var temp_dict: Dictionary
    temp_dict = {
        "frozen_obj_path": frozen_obj_path
    }
    stored_data = temp_dict
