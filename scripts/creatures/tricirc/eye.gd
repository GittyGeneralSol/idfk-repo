@tool

extends BaseCreatureEye

func _ready() -> void:
    super._ready()
    params = {
        "eye_type": TYPE.CIRCLE,
        "radius": 25,
        "draw_outline": false,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.YELLOW,
        "eyelid_color_bottom": Color.YELLOW
    }
