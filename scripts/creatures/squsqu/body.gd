@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.RECTANGLE,
        "body_color": Color.CHARTREUSE,
        "size": Vector2(170, 170)
    }
