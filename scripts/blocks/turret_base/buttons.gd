@tool

extends Node
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")
const POLYGON_BUTTON = preload("res://scenes/utility/polygon_button.tscn")

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = 5.0 * sqrt(2)
@export var outline_width: float = 3.0
@export var num_of_buttons: int = 2
@export var button_colors: PackedColorArray = [Color.CHARTREUSE, Color.YELLOW]
@export var action_strings: PackedStringArray = ["toggle_turret", "upgrade_turret"]
@export var cooldown_after_press: float = 0.5
@export var displacement_x: float = 13 - Constants.half_block_extent
@export var initial_displacement_y: float = 13 - Constants.half_block_extent
@export var progressive_displacement_y: float = 17
@export var rotation_deg: float = -45.0
"button_colors"
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
        current_button.cooldown_after_press = cooldown_after_press
        
        ## Connect the current_button's signals to this node's on_button_downed and release function:
        current_button.connect("button_downed", Callable(self, "on_button_down"))
        current_button.connect("button_released", Callable(self, "on_button_release"))
        current_button.connect("button_press_canceled", Callable(self, "on_button_press_cancellation"))
        print("Connected 'button_released' and 'button_downed' signals for button: ", action_strings[button_number]) # Debug print
        
        add_child(current_button)

func on_button_down(action_string: String):
    print("TB - BUTTONS - Button downed: ", action_string)
    
func on_button_release(action_string: String):
    print("TB - BUTTONS - Button released: ", action_string)
    
    ## Toggle turret:
    if action_string == "toggle_turret" and get_turret():
        get_turret().toggle_turret()

func on_button_press_cancellation(action_string: String):
    print("TB - BUTTONS - Button released: ", action_string)
    
func get_turret() -> Node:
    return get_parent().get_turret()
