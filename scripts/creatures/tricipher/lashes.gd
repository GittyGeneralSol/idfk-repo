@tool

extends BaseCreatureDeco

func _ready() -> void:
    set_params()

func set_params():
    var new_stack: Array[Dictionary]  
    var bowtie = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.HOURGLASS,
        "width": 35,
        "length": 50,
        "scale": Vector2(0.45, 0.45),
        "notch_width": 5,
        "color": Color.BLACK,
        "position": Vector2(0, 33),
        "rotation": 90
    }
    
    new_stack.append(bowtie)
    shape_stack = new_stack
    
