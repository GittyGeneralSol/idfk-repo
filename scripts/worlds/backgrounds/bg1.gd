@tool

extends Node2D

@onready var bg_size: Vector2 # world_size * Constants.tile_size + Vector2(Constants.tile_size, Constants.tile_size)
@onready var bg_color: Color
@export var z_ind: int = -500

func _setup_bg():
    z_as_relative = true
    z_index = z_ind
    var parent = get_parent_world()
    
    bg_size = parent.world_size * Constants.tile_size + Vector2(Constants.tile_size, Constants.tile_size)
    bg_color = parent.bg_color
    queue_redraw()

func _draw() -> void:
    draw_simple_bg()

func draw_simple_bg():
    print("\nbg_size: ", bg_size, "\n")
    var bg_rect = Rect2(-bg_size/2, bg_size)
    draw_rect(bg_rect, bg_color)
    
    var outline_size = bg_size + Vector2(Constants.tile_size, Constants.tile_size)
    var bg_outline_rect = Rect2(-outline_size/2, outline_size)
    draw_rect(bg_outline_rect, Color.BLACK, false, Constants.tile_size)

func get_parent_world() -> Node:
    ## Check two ancestors up:
    if get_parent():
        if get_parent() is World: return get_parent()
        elif get_parent() is not World and get_parent().get_parent() and get_parent().get_parent() is World: return get_parent().get_parent()
        else: return null
    else: return null
