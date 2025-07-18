@tool
extends Node2D

# The raw parameters for the effect.
@export var num_points: int = 6
@export var circumrad: float = 125.0
@export var shape_color: Color = Color.SLATE_GRAY
@export var displacement: Vector2 = Vector2.ZERO
@export var rotation_deg: float = -45.0
@export var num_of_rings: int = 4

@export var shapes: Array[CustomShapeLogic]:
    set(v): shapes = v; queue_redraw()

func _ready() -> void:
    generate()

# This function must be called to generate/update the shapes.
func generate():
    var new_shapes: Array[CustomShapeLogic] = []
    
    # The logic from your _draw loop.
    for ring_number in num_of_rings:
        var subtract_color = Color(0.025, 0.025, 0.025, 0) * ring_number
        var subtract_cirrad = 35.0 * ring_number
        var current_color = shape_color - subtract_color
        var current_radius = circumrad - subtract_cirrad
        var current_num_points = num_points if ring_number % 2 == 0 else 4
    
        var params = {
            "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
            "num_points": current_num_points,
            "radius": current_radius,
            "color": current_color,
            "position": displacement,
            "rotation": rotation_deg
        }
        
        var shape = CustomShapeLogic.new(params)
        new_shapes.append(shape)
    
    # Assign the final array.
    shapes = new_shapes
    
func _draw() -> void:
    if not shapes:
        return
        
    for shape_logic in shapes:
        shape_logic.draw_on(self)
