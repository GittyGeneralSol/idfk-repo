@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.REULEAUX,
        "body_color": Color.HOT_PINK,
        "radius": 85,
        "shape_rotation": -90
    }
