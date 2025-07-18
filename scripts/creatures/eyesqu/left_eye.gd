@tool

extends BaseCreatureEye

func _ready() -> void:
    super._ready()
    
    params = {
        "eye_type": TYPE.RECTANGLE,
        "size": Vector2(140, 140),
        "draw_outline": true,
        "outline_color": Color.DODGER_BLUE.darkened(0.05),
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.DODGER_BLUE.darkened(0.1),
        "eyelid_color_bottom": Color.DODGER_BLUE.darkened(0.1)
    }
    
    return
    params = {
        "eye_type": TYPE.MIX,
        "stack": [
            {
                "shape_type": TYPE.CIRCLE,
                "radius": 50 / sqrt(2),
                "eye_color": Color.WHITE
            },
            {
                "shape_type": TYPE.HOURGLASS,
                "eye_color": Color.WHITE,
                "position": Vector2(0, -50)
            }
        ],
        "draw_outline": false,
        "eyelid_color_bottom": Color.BLACK,
        "scale": Vector2(2, 2)
    }
    
