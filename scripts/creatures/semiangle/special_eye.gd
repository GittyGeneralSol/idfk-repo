@tool
extends BaseCreatureEye

func _ready() -> void:
    super._ready()
    set_params()

func set_params():
    params = {
        "eye_type": TYPE.MIX,
        "boolean_operation": CustomShapeLogic.BooleanOperation.SUBTRACTION,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "angle": 180.0,
                "radius": 85
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
                "position": Vector2(0, -45),
                "size": Vector2(200, 100),
            }
        ],
        "shape_scale": Vector2(0.8, 0.8),
        "draw_outline": false,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.ORANGE,
        "eyelid_color_bottom": Color.ORANGE
    }
