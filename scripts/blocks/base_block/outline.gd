@tool
extends Node2D

@export_group("Shape Configuration")
@export var size: float = Constants.tile_size
@export var rotation_deg: float = 0.0

@export_group("Appearance")
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 10.0

@export var shape: CustomShapeLogic:
    set(v): shape = v; queue_redraw()

func _ready() -> void:
    generate_shape()

func generate_shape():
    var shape_params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
        "size": Vector2.ONE * size + Vector2.ONE * outline_width * 2,
        "color": outline_color,
        "rotation": rotation_deg
    }
    
    shape = CustomShapeLogic.new()
    shape.update_from_params(shape_params)
    
func _draw() -> void:
    if is_instance_valid(shape):
        shape.draw_on(self)
