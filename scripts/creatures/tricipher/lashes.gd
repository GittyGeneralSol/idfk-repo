@tool

extends BaseCreatureDeco

func _ready() -> void:
    set_params()

func set_params():
    var new_stack: Array[Dictionary]
    #var lash_number: int = 3
    #
    #var angle_step = 26
    #for i in lash_number:
        #var angle = angle_step * i - angle_step - 90
        #var pos = Vector2.RIGHT.rotated(deg_to_rad(angle)) * 28
        #var lash = {
            #"shape_type": CustomShapeLogic.SHAPE_TYPE.TRIANGLE,
            #"gen_type": ShapeGens.TriangleGenerator.GenerationType.ISOSCELES,
            #"scale": Vector2.ONE * 1.6,
            #"size": Vector2(5, 10),
            #"color": Color.BLACK,
            #"position": pos,
            #"rotation": angle + 90
        #}
        #new_stack.append(lash)
        
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
    
    var cane = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.SYMBOL,
        "position": Vector2(20, 50),
        "rotation": 35,
        "color": Color.BLACK,
        "symbol": "cane"
    }
    
    new_stack.append(cane)
    
    shape_stack = new_stack
    
