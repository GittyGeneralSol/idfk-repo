@tool

extends BaseCreatureDeco

@export var pos: Vector2 = Vector2.ZERO:
    set(v): pos = v; set_params()

func _ready():
    set_params()

func set_params():
    var hat = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.MIX,
        "scale": Vector2(1.5, 1.5),
        "position": Vector2(0, -115),
        "color": Color.BLACK,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
                "size": Vector2(15, 40),
                "position": Vector2(0, -20)
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
                "size": Vector2(7, 30),
                "position": Vector2(0, 0),
                "rotation": -90
            }
        ]
    }
        
    shape_stack = [hat]
    
