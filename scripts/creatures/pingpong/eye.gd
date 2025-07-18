@tool

extends BaseCreatureEye

func _ready() -> void:
    super._ready()
    params = {
        "eye_type": TYPE.STAR,
        "lid_type": LID_TYPE.OMNI,
        "num_points": 5,
        "outer_radius": 50,
        "inner_radius": 25,
        "draw_outline": true,
        "outline_color": Color.GOLDENROD,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color("f1b912"),
        "eyelid_color_bottom": Color("f1b912"),
        "shape_position": "PROP-/body/params/shape_position",
        "shape_rotation": 90
    }
