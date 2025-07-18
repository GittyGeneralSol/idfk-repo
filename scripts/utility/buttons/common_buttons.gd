@tool

extends Control
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")
const POLYGON_BUTTON = preload("res://scenes/utility/polygon_button.tscn")

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = 25 * sqrt(2)
@export var outline_width: float = 10.0
@export var num_of_buttons: int = 4
@export var button_colors: PackedColorArray = [Color.CHARTREUSE, Color.ROYAL_BLUE, Color.DEEP_SKY_BLUE, Color.LIGHT_SLATE_GRAY]
@export var action_strings: PackedStringArray = ["button_one", "game_load", "build_button", "default"]
@export var displacement_x: float = 60
@export var initial_displacement_y: float = 60
@export var progressive_displacement_y: float = 80
@export var rotation_deg: float = -45.0

@export var outline_correction: float = -2.5001

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
        current_button.switch_button_color = button_colors[button_number]
        current_button.position = Vector2(displacement_x, progressive_displacement_y * button_number + initial_displacement_y)
        current_button.rotation_deg = rotation_deg
        current_button.outline_correction = outline_correction
        current_button.action_string = action_strings[button_number]
        
        ## Connect the current_button's signals to this node's on_button_downed and release function:
        current_button.connect("button_downed", Callable(self, "on_button_down"))
        current_button.connect("button_released", Callable(self, "on_button_release"))
        current_button.connect("button_press_canceled", Callable(self, "on_button_press_cancellation"))
        print("Connected 'button_released' and 'button_downed' signals for button: ", action_strings[button_number]) # Debug print
        
        add_child(current_button)

func on_button_down(action_string: String):
    print("COMMON BUTTONS - Button downed: ", action_string)
    
    if action_string == "button_one":
        _on_save_button_pressed()
        print("\n!!GAME SAVED!!\n")
    
    if action_string == "game_load":
        _on_load_button_pressed()
        print("\n!!SAVE LOADED!!\n")
    
func on_button_release(action_string: String):
    print("COMMON BUTTONS - Button released: ", action_string)

func on_button_press_cancellation(action_string: String):
    print("COMMON BUTTONS - Button press canceled: ", action_string)

func _on_save_button_pressed():
    var active_worlds = WorldUtils.get_worlds_by_void()
    
    for world in active_worlds:
        var world_data: Dictionary = SaveManager._formulate_world_data(world)
        SaveManager.save_world(world_data, world.world_name, Vars.save_slot_number)
    
    ## Formulate and save data for player:
    SaveManager._form_and_save_player_data()

func _on_load_button_pressed():
    var active_worlds = WorldUtils.get_worlds_by_void()
    print("LOAD - Active Worlds: ", active_worlds)
    
    ## Load and apply data for active worlds
    for world in active_worlds:
        var world_name = world.world_name
        var loaded_data = SaveManager.load_world(world_name, Vars.save_slot_number)       
        SaveManager.apply_world_data(loaded_data, world)
    
    ## Load and apply data for player:
    SaveManager._load_and_apply_player_data()
       
