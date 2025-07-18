@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.CIRCLE,
        "body_color": Color.GOLD,
        "radius": 85,
        "shape_position": Vector2.ZERO
    } 
    
