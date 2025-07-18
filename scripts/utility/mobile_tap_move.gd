extends Node

@export var player_node: BaseCreature # Use BaseCreature type hint for clarity
# @onready var player_node: Node = get_node("../Player") # Your @onready is fine if the path is correct

# Track the direction determined by the initial touch down
var active_move_direction: Vector2 = Vector2.ZERO

var screen_half_width: float
var screen_half_height: float

# Cache viewport size
var viewport_size: Vector2


func _ready():
    player_node = get_tree().root.find_child("Player", true, false)
    
    if player_node == null:
        print("ERROR: MobileTapMove node has no Player node assigned! Path check needed?")
        set_process_mode(Node.PROCESS_MODE_DISABLED)
        return

    # Get and store screen size (assuming it doesn't change runtime - if it does, update in _process)
    viewport_size = get_viewport().size
    screen_half_width = viewport_size.x / 2.0
    screen_half_height = viewport_size.y / 2.0
    print("MobileTapMove: Screen size H/W: ", screen_half_height, "/", screen_half_width)

    # We need to receive input events
    set_process_mode(Node.PROCESS_MODE_PAUSABLE) # Allows pausing with the scene tree

    # If this node is a Control, ensure its Mouse -> Filter property is 'Ignore'
    # if you want touches that START on it to fall through to _input.

# --- NEW PUBLIC FUNCTION: Directly control input processing ---
func set_movement_input_active(active: bool):
    var player_node = WorldUtils.get_player_node()
    
    if active and player_node:
        set_process_mode(Node.PROCESS_MODE_PAUSABLE) # Re-enable input processing
        print("MobileTapMove: MobileTapMove input ENABLED.")
    else:
        set_process_mode(Node.PROCESS_MODE_DISABLED) # Disable all input processing
        active_move_direction = Vector2.ZERO # Immediately stop any current movement
        print("MobileTapMove: MobileTapMove input DISABLED. Active direction set to ZERO.")
        

# This function receives all input events that are not consumed by GUI elements above it
# MobileTapMove.gd

func _unhandled_input(event: InputEvent):
    var not_move_condition = (Vars.is_menu_open or Vars.pinching_screen or Vars.in_any_mode())
    if not_move_condition:
        active_move_direction = Vector2.ZERO
        return

    # Filter to only care about ScreenTouch and MouseButton for initial press/release
    if not (event is InputEventScreenTouch or event is InputEventMouseButton):
        return

    # --- Handle Touch Press ---
    if event.is_pressed():
        var touch_pos = event.position
        var dist_to_center_x = abs(touch_pos.x - screen_half_width)
        var dist_to_center_y = abs(touch_pos.y - screen_half_height)

        var primary_direction = Vector2.ZERO
        if dist_to_center_x > dist_to_center_y:
            primary_direction = Vector2.LEFT if touch_pos.x < screen_half_width else Vector2.RIGHT
        else:
            var center_dead_zone = dist_to_center_y / 4
            if dist_to_center_x < center_dead_zone and dist_to_center_y < center_dead_zone:
                 primary_direction = Vector2.ZERO
            else:
                primary_direction = Vector2.UP if touch_pos.y < screen_half_height else Vector2.DOWN
        active_move_direction = primary_direction

    # --- Handle Touch Release ---
    elif (event is InputEventScreenTouch or event is InputEventMouseButton) and !event.is_pressed():
        active_move_direction = Vector2.ZERO


# The _process function will now correctly stop calling attempt_move_step
# if active_move_direction is ZERO because Vars.is_ui_interacting caused it to be reset.
func _process(delta):
    if not player_node:
        player_node = get_tree().root.find_child("Player", true, false)
    
    if not player_node:
        return
    
    if active_move_direction != Vector2.ZERO:
        player_node.attempt_move_step(active_move_direction)


# --- Helper function to be called by your mobile detection script ---
# This function should be called when the script is enabled/disabled by
# your OS detection logic or menu system.
func set_input_active(active: bool):
    # Enable/disable processing of this script
    set_process_mode(Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED)

    # If disabling, make sure the active direction is reset
    if not active:
        active_move_direction = Vector2.ZERO
        print("Mobile tap input disabled")
    else:
        print("Mobile tap input enabled")
