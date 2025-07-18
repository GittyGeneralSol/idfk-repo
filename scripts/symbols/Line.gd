@tool
extends ShapeLogicRenderer

@export var shape_scale: Vector2 = Vector2.ONE:
    set(v): shape_scale = v; update_stack()
    
@export_range(-89.9, 89.9, 0.01) var shape_slant: float = 0.0:
    set(v): shape_slant = v; update_stack()
    
@export var shape_pos: Vector2 = Vector2.ONE:
    set(v): shape_pos = v; update_stack()
    
func _ready() -> void:
    print("Node Transform: ", transform)
    update_stack()
    
func update_stack():
    override_color = Color.AQUA
    draw_mode = DrawMode.UNION
    
    var cane = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.MIX,
        "scale": Vector2(1.5, 1.5),
        "color": Color.BLACK,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
                "size": Vector2(7, 90),
                "position": Vector2(0, -20)
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.MIX,
                "position": Vector2(13.75, -60),
                "scale": Vector2(0.7, 1),
                "boolean_operation": CustomShapeLogic.BooleanOperation.SUBTRACTION,
                "stack": [
                    {
                        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                        "radius": 25,
                        "angle": -180
                        
                    },
                    {
                        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                        "radius": 15,
                        "angle": -180
                        
                    }
                ]
            }
        ]
    }
    
    
    var new_stack: Array[Dictionary] = [cane]
    logic_stack = get_logic_stack_from_param_stack(new_stack)
