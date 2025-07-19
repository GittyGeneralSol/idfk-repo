@tool

extends BaseCreatureDeco


func _ready() -> void:
    set_params()

func set_params():
    var new_stack: Array[Dictionary]
    var cane = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.SYMBOL,
        "position": Vector2(20, 50),
        "rotation": 35,
        "color": Color.BLACK,
        "symbol": "cane"
    }
    
    new_stack.append(cane)
    shape_stack = new_stack

## Legacy code for animation 'cane_swing'
func _form_cane_swing_anim():
    var animation = Animation.new()
    animation.length = 0.8
    animation.loop_mode = Animation.LOOP_PINGPONG
    
    # Rotation
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC_ANGLE)
    animation.track_set_path(track_index, "eye_system/cane:rotation")
    animation.track_insert_key(track_index, 0.0, 0)
    animation.track_insert_key(track_index, 0.5, deg_to_rad(45))
    animation.track_insert_key(track_index, 0.65, deg_to_rad(220), 0.65)
    animation.track_insert_key(track_index, 0.8, 0)
    
    # Position
    track_index = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
    animation.track_set_path(track_index, "eye_system/cane:position")
    animation.track_insert_key(track_index, 0.0, Vector2.ZERO)
    animation.track_insert_key(track_index, 0.15, Vector2.ZERO)
    animation.track_insert_key(track_index, 0.65, Vector2(50, 0))
    animation.track_insert_key(track_index, 0.8, Vector2.ZERO)
