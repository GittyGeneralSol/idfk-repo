@tool

extends BaseCreatureDeco

@onready var _animator: AnimationPlayer = $"../../AnimationPlayer"

func _ready() -> void:
    set_params()
    
    var path = _animator.get_path_to(self)
    print("path_to_cane: ", path)

func set_params():
    var new_stack: Array[Dictionary]
    var cane = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.SYMBOL,
        "position": Vector2(20, 50),
        "rotation": 35,
        "color": Color.BLACK,
        "symbol": "cane"
    }
    
    new_stack.append(cane)
    shape_stack = new_stack
    
