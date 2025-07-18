@tool
extends ShapeLogicRenderer

@export var shape_scale: float = 1.0:
    set(v): shape_scale = v; update_stack()
    
@export_range(-89.9, 89.9, 0.01) var shape_skew: float = 1.0:
    set(v): shape_skew = v; update_stack()

func _ready() -> void:
    print("Node Transform: ", transform)
    update_stack()
    
func update_stack():
    var new_stack: Array[CustomShapeLogic]
    var shape_params: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.SYMBOL,
        "color": Color.BLACK,
        "symbol": "a",
        "scale": shape_scale,
        "skew": shape_skew
    }
    
    var shape_logic = CustomShapeLogic.new(shape_params)
    new_stack.append(shape_logic)
    logic_stack = new_stack
