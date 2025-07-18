@tool

extends BaseCreatureMainBody

func _ready() -> void:
    super._ready()
    update_params()
    await get_tree().process_frame
    get_parent_creature(self).print_tree_pretty()

func update_params():
    params = {
        "body_type": TYPE.RECTANGLE,
        "body_color": Color.DODGER_BLUE,
        "size": Vector2(170, 170),
        "clip_child_parts": true
    }
