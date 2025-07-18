@tool

extends Node

var tile_map: Dictionary = {}
var camera_zoom: float = 2.0 ## Used to determine loudness of sounds
var pinching_screen: bool = false
var world_size: Vector2 = Vector2(10, 10)
var world_size_p: Vector2 = world_size * Constants.tile_size
var hwe: Vector2 = world_size / 2
var hwe_p: Vector2 = hwe * Constants.tile_size ## Half World Extent in pixels
var room_speed_factor: float = 1.0

var is_menu_open: bool = false
var build_mode: bool = false
var destroy_mode: bool = false

# Save Slot:
var save_slot_number: int = 31

# Reference to the MobileTapMove node
@onready var mobile_tap_move_node: Node

## Operating system
var platform_name = OS.get_name()
# Check if the platform is android or IOS
var is_mobile: bool = (platform_name == "Android" or platform_name == "IOS")

func _ready() -> void:
    mobile_tap_move_node = get_tree().root.find_child("MobileTapMove", true, false)
    print("\nDetected platform: ", platform_name, "\n")
    
    if is_mobile:
        print("Mobile platform detected.")
    else:
        print("Not a mobile platform.")
        
func in_any_mode() -> bool:
    var condition = (build_mode or destroy_mode)
    if condition:
        return true
    else: return false
        
func set_mobile_tap_move(value: bool):
    mobile_tap_move_node.set_movement_input_active(value)
