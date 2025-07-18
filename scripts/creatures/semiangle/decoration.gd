@tool

extends BaseCreatureDeco

func _ready() -> void:
    set_params()

func set_params():
    var circle = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
        "radius": 20.0,
        "color": Color.SPRING_GREEN.lightened(0.4),
    }
    
    shape_stack = [circle]
    
