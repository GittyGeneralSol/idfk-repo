@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.POLYGON,
        "body_color": Color.DARK_RED,
        "draw_outline": true,
        "num_points": 6,
        "radius": 280
    }
