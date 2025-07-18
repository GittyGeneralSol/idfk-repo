@tool

extends BaseCreatureDeco

func _ready() -> void:
    set_params()

func set_params():
    var triangle_top = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "radius": 5.0,
        "color": Color.SPRING_GREEN.lightened(0.4),
        "position": Vector2(0, -20),
        "rotation": -90
    }
    
    var triangle_bottom = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "radius": 5.0,
        "color": Color.SPRING_GREEN.lightened(0.4),
        "position": Vector2(0, 20),
        "rotation": 90
    }
    
    shape_stack = [triangle_top, triangle_bottom]
    
