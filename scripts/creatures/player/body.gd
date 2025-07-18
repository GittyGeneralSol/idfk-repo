@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()

func update_params():
    params = {
        "body_type": TYPE.RECTANGLE,
        "body_color": Color.GRAY,
        "size": Vector2(170, 170)
    }

    var bb_info = get_bb_info()
    print("BB: ", bounding_box)
    
func _draw():
    super._draw()
    var size = Vector2(200, 200)
    var rect = Rect2(-size/2, size)
    draw_rect(rect, Color(Color.WHITE, 0.25), true)
