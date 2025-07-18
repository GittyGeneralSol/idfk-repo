@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.POLYGON,
        "body_color": Color("9944ff"),
        "shape_rotation": -90,
        "radius": 100,
        "num_points": 5
    }
