@tool

extends World

@onready var world_name: String = "world_1"
@onready var default_speed_factor := 1.0
@onready var boundary_block: String = "wall"

## References to other worlds:
@onready var observer_worlds: PackedStringArray = ["world_0", "world_3"]
@onready var world_refs: PackedStringArray = ["world_2"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:    
    add_to_group("worlds")
    background._setup_bg()
    initialize_astar_grid()
    create_boundary() 
    create_blocks()
    #create_objects()
    
    ## After initialization phase, create creatures/
    #create_player()
    
    print("\nWORLD ", self, " - WORLD_SIZE: ", world_size, "\n")

func create_boundary():
    
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
    
    create_block(Vector2(-8,3), "wall")
    create_block(Vector2(-7,3), "wall")
    create_block(Vector2(-6,3), "wall")
    create_block(Vector2(-5,3), "wall")
    create_block(Vector2(-8,4), "wall")
    create_block(Vector2(-8,5), "wall")
    create_block(Vector2(-8,6), "wall")
    create_block(Vector2(-8,8), "wall")
    create_block(Vector2(-8,8), "wall")
    create_block(Vector2(-7,8), "wall")
    create_block(Vector2(-6,8), "wall")
    create_block(Vector2(-5,8), "wall")
    create_block(Vector2(-4,3), "wall")
    create_block(Vector2(-4,4), "wall")
    create_block(Vector2(-4,5), "wall")
    create_block(Vector2(-4,6), "wall")
    create_block(Vector2(-4,8), "wall")
    
    #create_block(Vector2(-1, 1), "pocket_dim_box", ["target_world_name", world_refs[0]])
    
    ## Prison
    for x in 3:
        for y in 3:
            var pos = Vector2(x, y) - Vector2(5, 5)
            if (x == 1 && y == 1): pass
            else: create_block(pos, "stone_block")

    create_block(Vector2(1,1), "stone_block")
    create_block(Vector2(2,1), "metal_block")
    create_block(Vector2(2,2), "stone_block")
    create_block(Vector2(2,3), "freeze_pod", { "frozen_obj_path": "blocks/stone_block" })
    create_block(Vector2(2,4), "turret_base", { "turret_name": "shield" })
    create_block(Vector2(2,5), "turret_base", { "turret_name": "x_shooter" })
    create_block(Vector2(3,1), "tree_stump")
    create_block(Vector2(3,2), "tree_stump")
    create_block(Vector2(3,3), "freeze_pod", { "frozen_obj_path": "creatures/squsqu" })
    create_block(Vector2(4,3), "tree_stump")
    create_block(Vector2(4,5), "freeze_pod")
    create_block(Vector2(7,4), "wall")
    create_block(Vector2(7,5), "wall")
    create_block(Vector2(7,6), "wall")
    create_block(Vector2(7,7), "wall")
    create_block(Vector2(8,6), "freeze_pod")
    create_block(Vector2(8,7), "turret_base", { "turret_name": "x_shooter" })

func create_player(args: Dictionary = {}):
    create_creature(Vector2.ZERO, "player", args)
