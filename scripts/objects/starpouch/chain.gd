@tool

extends Node2D

@onready var h_interval: int = 4
@onready var v_interval: int = 4
@onready var total_teeth = 10
@onready var maximum_h_displ = total_teeth * h_interval
@onready var tooth_size = Vector2(h_interval, v_interval)

func _draw() -> void:
    _draw_teeth()
    _draw_zipper_head()

func _draw_teeth(): 
    for i in total_teeth:
        var rel_h_displ = i * h_interval ## zero initially
        var h_displ = rel_h_displ - ( maximum_h_displ / 2 ) 
        var rel_v_displ = -v_interval/2 if(i % 2 == 0) else +v_interval/2
        var v_displ = rel_v_displ - v_interval/2
        var displ = Vector2(h_displ, v_displ)
        var current_rect = Rect2(displ, tooth_size)
        draw_rect(current_rect, Color.SILVER, true)

func _draw_zipper_head():
    var zipper_h_pos = (maximum_h_displ / 2) - h_interval
    var zipper_v_pos = -v_interval - v_interval/2
    var zipper_pos = Vector2(zipper_h_pos, zipper_v_pos)
    
    var zipper_size = tooth_size + Vector2(tooth_size.x * 0.5, tooth_size.y * 2)
    var zipper_rect = Rect2(zipper_pos, zipper_size)
    draw_rect(zipper_rect, Color.SILVER, true)
    
    print(zipper_pos)
