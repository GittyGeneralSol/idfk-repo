@tool

extends ShapeLogicRenderer

@onready var hexhuge: BaseCreature = $".."
@onready var body: BaseCreatureMainBody = $"../body"
@onready var body_bounding_box: Rect2
@onready var gridly_bounding_box: Rect2

func _ready() -> void:
    if true:
        return
    
    var bb_info = body.get_bb_info()
    body_bounding_box = bb_info.get("bounding_box")
    gridly_bounding_box = bb_info.get("gridly_bounding_box")
    var size = bb_info.get("size")
    var x_length = bb_info.get("length_x")
    var y_length = bb_info.get("length_y")
    var size_in_tiles = bb_info.get("size_in_tiles")
    var size_in_tiles_p = bb_info.get("size_in_tiles_p")
    
    var new_stack: Array[CustomShapeLogic]
    var params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.LINE,
        "length": x_length,
        "width": 10,
        "rotation": 0.0
    }
    
    var shape_logic = CustomShapeLogic.new(params)
    new_stack.append(shape_logic)
    
    params = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.LINE,
        "length": y_length,
        "width": 10,
        "rotation": -90.0
    }
    
    shape_logic = CustomShapeLogic.new(params)
    new_stack.append(shape_logic)
    
    logic_stack = new_stack
    
func _draw() -> void:
    super._draw()
    draw_rect(body_bounding_box, Color(Color.DARK_RED, 0.25), true)
    draw_rect(gridly_bounding_box, Color(Color.WHITE, 0.25), true)
