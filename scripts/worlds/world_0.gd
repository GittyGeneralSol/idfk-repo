@tool

extends PocketDimension

@onready var world_name: String = "world_0"
@onready var default_speed_factor := 1.0
@onready var boundary_block: String = "wall"
@onready var anchor_pos_override: Vector2i = Vector2i.ZERO

## References to other worlds
@onready var observer_worlds: PackedStringArray = []
@onready var world_refs: PackedStringArray = ["world_1"]

func _ready() -> void:
    super._ready()
    anchor_pos = anchor_pos_override
    create_boundary()
    create_blocks()
    
    ## Since this is starter world, it will have to ready itself.
    world_readied = true
    
    print("_loaded_scenes: ", _loaded_scenes)

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
    create_block(Vector2(4, 0), "stone_block")
    create_block(Vector2(3, 0), "turret_base", { "turret_name": "x_shooter" })
    #create_block(Vector2(4, -1), "pocket_dim_box", { "target_world_name": world_refs[0]})
    create_creature(Vector2(0, 5), "semiangle", { "max_hp": 200, "hp": 200, "name": "Bob" })
    create_creature(Vector2(0, -5), "tricirc")
    create_creature(Vector2(-5, 0), "tricipher")
    create_creature(Vector2(-4, 0), "tristar")
