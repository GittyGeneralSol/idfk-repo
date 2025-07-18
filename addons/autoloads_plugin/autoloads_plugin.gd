@tool
extends EditorPlugin

var save_manager_instance
var shape_gen_instance

func _enter_tree():
    # This function is called when you enable the plugin in the editor.
    # It's the editor's equivalent of _ready().
    
    # 1. Create an instance of your existing autoload script.
    save_manager_instance = load("res://scripts/autoloads/SaveManager.gd").new()
    shape_gen_instance = load("res://scripts/autoloads/ShapeGens.gd").new()
    
    # 2. Give them names so you can find them.
    save_manager_instance.name = "SaveManager"
    shape_gen_instance.name = "ShapeGens"
    
    # 3. Add them to the editor's scene tree. This makes it "live".
    get_editor_interface().get_base_control().add_child(save_manager_instance)
    get_editor_interface().get_base_control().add_child(shape_gen_instance)

func _exit_tree():
    # This is called when the plugin is disabled.
    # Clean up the instances to prevent memory leaks.
    if is_instance_valid(save_manager_instance):
        save_manager_instance.queue_free()
        
    if is_instance_valid(shape_gen_instance):
        shape_gen_instance.queue_free()
