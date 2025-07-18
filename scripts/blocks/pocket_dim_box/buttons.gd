@tool

extends Node
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")
const POLYGON_BUTTON = preload("res://scenes/utility/polygon_button.tscn")
const MODAL = preload("res://scenes/utility/modal.tscn")
@onready var container: Container = $"../Container"
@onready var text_rect: Node2D = $"../layers/text_rect"

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = 5 * sqrt(2)
@export var outline_width: float = 3.0
@export var num_of_buttons: int = 3
@export var button_colors: PackedColorArray = [Color.CHARTREUSE, Color.AQUA, Color.DIM_GRAY]
@export var action_strings: PackedStringArray = ["toggle_visibility", "pdb_aqua", "pdb_dim_gray", "pdb_chartreuse"]
@export var displacement_x: float = 13 - Constants.half_block_extent
@export var initial_displacement_y: float = 13 - Constants.half_block_extent
@export var progressive_displacement_y: float = 17
@export var rotation_deg: float = -45.0

@export var outline_correction: float = -1.5001

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ## Create the buttons
    create_buttons()
    
func create_buttons():
    for button_number in num_of_buttons:
        var current_button = POLYGON_BUTTON.instantiate()
        current_button.num_points = num_points
        current_button.circumrad = circumrad
        current_button.outline_width = outline_width
        current_button.def_button_color = button_colors[button_number]
        
        if button_number != 0: current_button.switch_button_color = button_colors[button_number]
        else: current_button.switch_button_color = Color.CRIMSON
    
        current_button.position = Vector2(displacement_x, progressive_displacement_y * button_number + initial_displacement_y)
        current_button.rotation_deg = rotation_deg
        current_button.outline_correction = outline_correction
        current_button.action_string = action_strings[button_number]
        current_button.cooldown_after_press = 1.0
        
        ## Connect the current_button's signals to this node's on_button_downed and release function:
        current_button.connect("button_downed", Callable(self, "on_button_down"))
        current_button.connect("button_released", Callable(self, "on_button_release"))
        print("Connected 'button_released' and 'button_downed' signals for button: ", action_strings[button_number]) # Debug print
        
        add_child(current_button)

func on_button_down(action_string: String):
    print("PDB - BUTTONS - Button downed: ", action_string)
    
    ## Toggle visibility:
    if action_string == "toggle_visibility" and container.visible == true:
        container.set_visible(false)
    elif action_string == "toggle_visibility" and container.visible == false:
        container.set_visible(true)
    
    if action_string == "pdb_dim_gray":
        Vars.is_menu_open = true # Set
        var current_modal = MODAL.instantiate()
        
        current_modal.input_box_max_ch = 12
        
        ## Connect the current_button's signals to this node's on_button_downed and release function:
        current_modal.connect("modal_submitted", Callable(self, "on_modal_submission"))
        current_modal.connect("modal_canceled", Callable(self, "on_modal_cancellation"))
        print("Connected 'modal_submitted' and 'modal_canceled' signals for input modal.") # Debug print
        
        WorldUtils.get_gui_node().add_child(current_modal)
        
    if action_string == "pdb_aqua":
        var target_world_name = WorldUtils.get_parent_block(self).target_world_name
        var target_world = WorldUtils.get_world_by_void(target_world_name)
        print("PDB - BUTTONS - target_world: ", target_world)
        
func on_button_release(action_string: String):
    print("PDB - BUTTONS - Button released: ", action_string)
    
    if action_string == "pdb_aqua":
        var current_existing_player = WorldUtils.get_player_node()
        var target_world = WorldUtils.get_parent_block(self).target_world_name
        TransportManager.transport_from_to(current_existing_player, target_world)
    
func on_modal_submission(modal_output: String):
    print("PDB - Modal submitted: ", modal_output)
    text_rect.update_text(modal_output)
    Vars.is_menu_open = false # Unset
    
func on_modal_cancellation(modal_output: String):
    print("PDB - Modal cancelled: ", modal_output)
    Vars.is_menu_open = false # Unset
