@tool
extends BlockBody

@export_group("Shape Configuration")
@export var block_size: float = Constants.tile_size
@export var rotation_deg: float = 0.0

@export_group("Appearance")
@export var body_color: Color = Color.LIGHT_SLATE_GRAY

func _ready() -> void:
    generate_shape()

func generate_shape():
    params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
        "size": Vector2.ONE * size,
        "color": body_color,
        "rotation": rotation_deg
    }
