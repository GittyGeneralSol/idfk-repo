@tool
extends AnimationPlayer
class_name CreatureAnimator

var _animation_info: Dictionary # Main Data Object

# Main Public Func
func play_by_name(anim_name: String = "", custom_blend: int = -1, custom_speed: float = 1.0, start_delay: float = 0.0):
    anim_name = _animation_info.get("animation", "")
    
    if not (anim_name and anim_name != ""):
        return
    
    start_delay = _animation_info.get("start_delay", 0.0)
    if start_delay > 0.0:
        print("Delay?")
        await get_tree().create_timer(start_delay).timeout
    
    custom_blend = _animation_info.get("custom_blend", -1.0)
    custom_speed = _animation_info.get("custom_speed", 1.0)
    play(anim_name, custom_blend, custom_speed)
    
func stop_anim():
    stop()
