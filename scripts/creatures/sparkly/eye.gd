@tool

extends BaseCreatureEye

func _ready() -> void:
    super._ready()
    set_params()

func set_params():
    params = {
        "eye_type": TYPE.DIAMOND,
        "width": 12.5,
        "height": 25.0,
        "eye_color": Color.SPRING_GREEN.lightened(0.9),
        "eyelid_color_bottom": Color.SPRING_GREEN.darkened(0.2),
        "eyelid_color_top": Color.SPRING_GREEN.darkened(0.2)
    }
