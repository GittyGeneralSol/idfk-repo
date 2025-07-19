@tool
extends AnimationPlayer
    
func add_anim_to_animator(animation_name: String, library_name: String, animation_resource: Animation):
    # Get Library
    var library: AnimationLibrary
    if has_animation_library(library_name):
        library = get_animation_library(library_name)
    else:
        library = AnimationLibrary.new()
    
    # Add Animation
    library.add_animation(animation_name, animation_resource)
    
    # Return animator library to _animator
    remove_animation_library(library_name)
    add_animation_library(library_name, library)
    
func play_animation(anim_name: String):
    if has_animation(anim_name):
        play(anim_name)
        
func get_current_anim():
    return current_animation
