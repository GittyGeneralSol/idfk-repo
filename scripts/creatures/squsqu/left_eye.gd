@tool

extends BaseCreatureEye

func _ready() -> void:
    #params = {
        #"eye_type": TYPE.RECTANGLE,
        #"eye_size": Vector2(50, 50),
        #"draw_outline": false,
        #"eye_color": Color.WHITE,
        #"eyelid_color_top": Color.CHARTREUSE,
        #"eyelid_color_bottom": Color.CHARTREUSE
    #}
    
    params = {
        "eye_type": TYPE.MIX,
        "eye_color": Color.WHITE,
        "stack": [
            {
                "shape_type": TYPE.CIRCLE,
                "radius": 25,
            },
            {
                "shape_type": TYPE.HOURGLASS,
                "eye_color": Color.WHITE,
                "position": Vector2(0, -30),
                "width": 45.0,
                "height": 45.0,
                "notch_width": 22.5
            }
        ],
        "draw_outline": false,
        "eyelid_color_bottom": Color.CHARTREUSE,
        "eyelid_color_top": Color.CHARTREUSE,
        "shape_rotation": 45,
    }
    
