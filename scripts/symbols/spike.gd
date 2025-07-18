@tool
extends ShapeLogicRenderer

@export var shape_scale: Vector2 = Vector2.ONE:
    set(v): shape_scale = v; update_stack()
    
@export_range(-89.9, 89.9, 0.01) var shape_slant: float = 0.0:
    set(v): shape_slant = v; update_stack()
    
@export var arc_angle: float = 90.0:
    set(v): arc_angle = v; update_stack()

func _ready() -> void:
    print("Node Transform: ", transform)
    update_stack()
    
func update_stack():
    var new_stack: Array[CustomShapeLogic]
    var shape_params: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
        "angle": arc_angle,
        "color": Color.GRAY,
        "num_points": 32,
        "rotation": 0,
        "scale": shape_scale,
        "slant": shape_slant
    }
    
    var shape_logic = CustomShapeLogic.new(shape_params)
    new_stack.append(shape_logic)
    logic_stack = new_stack
    
    Polygon2D
