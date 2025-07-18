@tool
extends ShapeLogicRenderer

@export var shape_scale: Vector2 = Vector2.ONE:
    set(v): shape_scale = v; update_stack()
    
@export_range(-89.9, 89.9, 0.01) var shape_slant: float = 0.0:
    set(v): shape_slant = v; update_stack()
    
@export var shape_pos: Vector2 = Vector2.ONE:
    set(v): shape_pos = v; update_stack()
    
@export var private_logic_stack: Array[MultiShapeLogic]
    
func _ready() -> void:
    print("Node Transform: ", transform)
    update_stack()
    
func update_stack():
    override_color = Color.AQUA
    draw_mode = DrawMode.UNION
    
    var height: float = 100
    var width: float = 50.0
    
    var semicircle_top: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.MIX,
        "boolean_operation": CustomShapeLogic.BooleanOperation.SUBTRACTION,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "angle": 180,
                "radius": width/2,
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "position": Vector2(0, 60),
                "radius": 50,
            }
        ],
        "position": Vector2(0, -width/2),
        "rotation": 180,
        "scale": shape_scale,
        "slant": shape_slant
    }
    
    var rect: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
        "angle": 360.0,
        "size": Vector2(width, height/2),
        "color": Color.GRAY,
        "position": Vector2(0, 0),
        "rotation": 0,
        "scale": shape_scale,
        "slant": shape_slant
    }
    
    var semicircle_bottom: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
        "angle": 180,
        "radius": width/2,
        "color": Color.GRAY,
        "num_points": 32,
        "position": Vector2(0, width/2),
        "rotation": 0,
        "scale": shape_scale,
        "slant": shape_slant
    }
    
    
    var new_stack: Array[Dictionary] = [semicircle_top, rect, semicircle_bottom]
    private_logic_stack = get_multilogic_stack_from_param_stack(new_stack)
    
    queue_redraw()
    
func _draw() -> void:
    for logic in private_logic_stack:
        logic.draw_on(self)
