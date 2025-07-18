@tool

extends BaseCreatureDeco

func _ready() -> void:
    var star_shape_params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
        "radius": 85,
        "color": Color.GOLD.darkened(0.1),
        "filled": false,
        "width": 10.0
    }
    
    shape_stack = [star_shape_params]
