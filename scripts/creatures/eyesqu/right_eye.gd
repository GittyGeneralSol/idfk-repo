@tool

extends BaseCreatureEye

func _ready() -> void:
    params = {
        "eye_type": TYPE.RECTANGLE,
        "eye_size": Vector2(50, 50),
        "draw_outline": false,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.CHARTREUSE,
        "eyelid_color_bottom": Color.CHARTREUSE
    }
