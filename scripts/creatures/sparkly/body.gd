@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    set_params()

func set_params():
    params = {
        "body_type": TYPE.DIAMOND,
        "width": 25.0,
        "height": 50.0,
        "body_color": Color.SPRING_GREEN,
    }
