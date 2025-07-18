@tool

extends PocketDimension

@export var world_name: String = "unspecified_default"
@export var default_speed_factor := 1.0
@export var boundary_block: String = ""
@export var anchor_pos_override: Vector2i = Vector2i.ZERO

## References to other worlds
@onready var observer_worlds: PackedStringArray = []
@onready var world_refs: PackedStringArray = []

func _ready() -> void:
    super._ready()
    anchor_pos = anchor_pos_override
    create_boundary()
    create_blocks()

func create_boundary():
    
    if not boundary_block:
        return
    
    ## Corner Blocks:
    var hwe: Vector2 = world_size / 2 # HWE = half_world_extent
    create_block(hwe, boundary_block) # Bottom Right
    create_block(Vector2(-hwe.x, hwe.y), boundary_block) # Bottom Left
    create_block(Vector2(hwe.x, -hwe.y), boundary_block) # Top Right
    create_block(-hwe, boundary_block) # Top Left
    
    ## Sides:
    var number_of_blocks_per_h_side: int = world_size.x - 2 # Minus two corners
    var number_of_blocks_per_v_side: int = world_size.y - 2 # Minus two corners
    
    for block_num in number_of_blocks_per_h_side + 1:
        var grid_pos_x = block_num - floori(number_of_blocks_per_h_side/2)
        var grid_pos_y = hwe.y
        
        create_block(Vector2(grid_pos_x, grid_pos_y), boundary_block) # Bottom
        create_block(Vector2(grid_pos_x, -grid_pos_y), boundary_block) # Top
    
    for block_num in number_of_blocks_per_v_side + 1:
        var grid_pos_x = hwe.x
        var grid_pos_y = block_num - floori(number_of_blocks_per_v_side/2)
        
        create_block(Vector2(grid_pos_x, grid_pos_y), boundary_block) # Right
        create_block(Vector2(-grid_pos_x, grid_pos_y), boundary_block) # Left

func create_blocks():
    pass
