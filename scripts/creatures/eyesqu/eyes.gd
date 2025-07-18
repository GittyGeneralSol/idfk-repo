@tool

extends Node2D

@export var eye_offset = Vector2(50,0)
@export var eye_size: Vector2 = Vector2(50, 50)
@export var eyes_displacement = Vector2(-eye_size.x/2, -eye_size.y/2)
@onready var body: Node2D = get_parent().get_child(0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ## Trigger the first draw:
    queue_redraw()

func _draw() -> void:
    
    ## Eye Drawing logic:
    var left_eye_rect = Rect2(body.position - eye_offset + eyes_displacement, eye_size)
    var right_eye_rect = Rect2(body.position + eye_offset + eyes_displacement, eye_size)
    draw_rect(left_eye_rect, Color.WHITE, true, -1.0, false)
    draw_rect(right_eye_rect, Color.WHITE, true, -1.0, false)
