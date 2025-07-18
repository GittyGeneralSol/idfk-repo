@tool

extends BaseCreatureMainBody

@onready var decoration: Node2D = $decoration

func _ready() -> void:
    super._ready()
    update_params()
    update_deco()

func update_params():
    pulsing = true
    params = {
        "body_type": TYPE.POLYGON,
        "body_color": Color.YELLOW,
        "shape_rotation": -90,
        "radius": 85,
        "num_points": 3,
        "clip_child_parts": false
    }

func update_deco():
    if decoration:
        decoration.base_positions = points_body
