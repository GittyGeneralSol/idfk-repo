@tool

extends BaseCreatureEye

func _ready() -> void:
    params = {
        "eye_type": TYPE.REULEAUX,
        "lid_type": LID_TYPE.CIRCLE,
        "radius": 50,
        "draw_outline": false,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color("ff00a0"),
        "eyelid_color_bottom": Color("ff00a0"),
        "shape_rotation": -90
    }
