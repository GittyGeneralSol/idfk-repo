@tool

extends BaseCreatureEye

func _ready() -> void:
    pulsing = true
    params = {
        "eye_type": TYPE.STAR,
        "lid_type": LID_TYPE.OMNI,
        "num_points": 5,
        "outer_radius": 40,
        "inner_radius": 20,
        "draw_outline": false,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.AQUA,
        "eyelid_color_bottom": Color.AQUA,
        "blink_type": BLINK_TYPE.OPENNESS,
        "shape_rotation": -90,
    }
