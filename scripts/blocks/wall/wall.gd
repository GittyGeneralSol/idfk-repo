extends Block

class_name Wall # For identification that this is a wall

@onready var wall_lines: Node2D = $wall_lines

@export var is_frozen: bool = false ## If true, all wall lines will be drawn.
@export var parent_world: Node = get_parent()

func _ready() -> void:
    b_setup_variables("wall", _worldly_position)
    wall_lines.is_frozen = is_frozen

func get_parent_world_tile_map() -> Dictionary:
    if get_parent() and get_parent() is World and get_parent().current_tile_map: return get_parent().current_tile_map
    else: return {}
    
func update_block():
    super.update_block()
    
    # Trigger redraw on wall_lines
    wall_lines.queue_redraw()
