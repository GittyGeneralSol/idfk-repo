@tool
extends Control # Control type to absorb input

class_name ControlButton

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

@onready var button_area_2d: Area2D = $ButtonArea2D
@onready var collision_polygon_2d: CollisionPolygon2D = $ButtonArea2D/CollisionPolygon2D
@onready var cooldown_timer: Timer = $cooldown_timer # Requires a Timer node child named "cooldown_timer"

# --- Customize Appearance & Shape ---
@export_category("Appearance")
@export var num_points: int = 4
@export var snap_points: bool = true # Whether to use snappedi() for points or not
@export var circumrad: float = 25 * sqrt(2)
@export var outline_width: float = 10.0
@export var def_button_color: Color = Color.CRIMSON
@export var switch_button_color: Color = Color.CRIMSON
@export var rotation_deg: float = -45.0
@export var outline_correction: float = -2.5001 # Adjust outline size relative to body

@onready var curr_botton_color: Color # Initialized in _ready

## Button Shape Data (Calculated once)
var points_body: PackedVector2Array
var points_outline: PackedVector2Array

# --- Customize Behavior ---
@export_category("Behavior")
@export var action_string: String = "default" # Identifier for this button's action
@export var cooldown_after_press: float = 0.0 # Duration to disable listening after release (0 for no cooldown)
@export var is_listening: bool = true # Can be toggled externally

# --- Internal State ---
var is_pressed_visual: bool = false # True while button is visually pressed down
var is_hovered_over: bool = false   # True while mouse is over the Area2D (desktop hover)

# --- Signals ---
@export var connect_button_to_node: Node = null
# Emit the action_string for context.
signal button_downed(action_string) # Emits when button is pressed down
signal button_released(action_string) # Emits when button is released over the area
signal button_press_canceled(action_string) # Emits if button was pressed down, but pointer left the area before release

# Reference to the MobileTapMove node
@onready var mobile_tap_move_node: Node = get_tree().root.find_child("MobileTapMove", true, false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Initialize color
    curr_botton_color = def_button_color

    # --- Connect Area2D Signals (Essential for input detection) ---
    if button_area_2d:
        if !button_area_2d.is_connected("input_event", Callable(self, "_on_button_area_2d_input_event")):
            button_area_2d.connect("input_event", Callable(self, "_on_button_area_2d_input_event"))
        if !button_area_2d.is_connected("mouse_entered", Callable(self, "_on_button_area_2d_mouse_entered")):
             button_area_2d.connect("mouse_entered", Callable(self, "_on_button_area_2d_mouse_entered"))
        if !button_area_2d.is_connected("mouse_exited", Callable(self, "_on_button_area_2d_mouse_exited")):
             button_area_2d.connect("mouse_exited", Callable(self, "_on_button_area_2d_mouse_exited"))
    else:
        push_error("PolygonButton: ButtonArea2D not found! Input will not work.")

    # --- Connect Timer Signal ---
    if cooldown_timer:
        if !cooldown_timer.is_connected("timeout", Callable(self, "_on_cooldown_timer_timeout")):
            cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timer_timeout"))
    else:
         push_warning("PolygonButton: CooldownTimer not found! Cooldown will not work.")

    # --- Connect this button's signals to another node if specified ---
    # This pattern allows connecting signals in the editor OR through this export.
    # Connecting in the instantiating script (like CommonButtons) is often cleaner.
    if connect_button_to_node and is_instance_valid(connect_button_to_node): # Check if node is valid
        if connect_button_to_node.has_method("on_button_down"): connect("button_downed", Callable(connect_button_to_node, "on_button_down"))
        else: print("BUTTON %s: target_node lacks 'on_button_down' method." % action_string)
        if connect_button_to_node.has_method("on_button_release"): connect("button_released", Callable(connect_button_to_node, "on_button_release"))
        else: print("BUTTON %s: target_node lacks 'on_button_release' method." % action_string)
        if connect_button_to_node.has_method("on_button_press_canceled"): connect("button_press_canceled", Callable(connect_button_to_node, "on_button_press_canceled")) # Corrected method name
        else: print("BUTTON %s: target_node lacks 'on_button_press_canceled' method." % action_string)
    # else: # Handle no target node or connecting elsewhere

    # --- Calculate Shape Points (Relative to this node's origin) ---
    points_body = PolygonGenerator.generate_polygon_points(num_points, circumrad, Vector2.ZERO, rotation_deg, snap_points)
    points_outline = PolygonGenerator.generate_polygon_points(num_points, circumrad + outline_width + outline_correction, Vector2.ZERO, rotation_deg, snap_points)

    if points_outline.size() > 0:
         points_outline.append(points_outline[0]) # Close the outline polyline

    # --- Set Collision Polygon (Using calculated shape points) ---
    create_button_area()

    # --- Initial Draw ---
    queue_redraw()

# --- Drawing Function ---
func _draw():
    var current_drawing_col = curr_botton_color
    var outline_col = Color.BLACK # Outline color constant

    # Adjust color based on state
    if !is_listening: # Dim when on cooldown/not listening
        current_drawing_col = current_drawing_col.darkened(0.5) # Darken
    elif is_pressed_visual: # Darken when actively pressed
        current_drawing_col = current_drawing_col.darkened(0.3)
    elif is_hovered_over: # Lighten on hover
        current_drawing_col = current_drawing_col.lightened(0.2)


    # Draw outline then body
    if points_body.size() > 2:
        if points_outline.size() > 1:
             draw_polyline(points_outline, outline_col, outline_width)
        draw_polygon(points_body, [current_drawing_col])
    else: push_error("PolygonButton: Body polygon needs at least three points for drawing.")

# --- Set Collision Shape ---
func create_button_area():
    if collision_polygon_2d and points_body.size() > 2: # Ensure node and points are valid
        collision_polygon_2d.polygon = points_body
    # else: push_warning("PolygonButton: Collision polygon or points not ready.")


# --- Input Event Handling (Area2D Signal) ---
func _on_button_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if !(event is InputEventMouseButton or event is InputEventScreenTouch):
        return

    if event.is_pressed():
        if is_listening and !is_pressed_visual:
            is_pressed_visual = true
            queue_redraw()
            button_downed.emit(action_string)
            
            Vars.set_mobile_tap_move(false)
            

    elif !event.is_pressed(): # This covers release
        if is_pressed_visual:
            is_pressed_visual = false
            queue_redraw()
            button_released.emit(action_string)

            if is_listening and cooldown_after_press > 0.0:
                disallow_listening(cooldown_after_press)
            color_switch()
            
        Vars.set_mobile_tap_move(true)
  
                

# --- Mouse Entered/Exited Handling (Area2D Signals) ---
func _on_button_area_2d_mouse_entered():
    # Enable hover visual only if not on mobile and not already pressed
    # Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) checks if the left button is currently held down globally
    if !Vars.is_mobile and !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        is_hovered_over = true
        queue_redraw()
        # print("Mouse Enter Hover: ", action_string) # Debug

func _on_button_area_2d_mouse_exited():
    # Disable hover visual
    if is_hovered_over:
        is_hovered_over = false
        queue_redraw()
        # print("Mouse Exit Hover: ", action_string) # Debug

    # If the button was visually downed (pressed) and the pointer left, it's a cancellation
    if is_pressed_visual:
        is_pressed_visual = false # Reset visual state
        queue_redraw() # Update drawing
        button_press_canceled.emit(action_string) # Emit cancel signal
        # print("Button Press Canceled: ", action_string) # Debug

# --- Cooldown Logic ---
func disallow_listening(duration: float = 1.0):
    if !is_listening: return # Already not listening

    is_listening = false
    if cooldown_timer:
        cooldown_timer.wait_time = duration
        cooldown_timer.start()
        queue_redraw() # Redraw to show cooldown state


func _on_cooldown_timer_timeout() -> void:
    is_listening = true
    queue_redraw() # Redraw to show button is active again


# --- Color Switching Logic ---
func color_switch():
    if switch_button_color != def_button_color:
        if curr_botton_color == def_button_color:
            curr_botton_color = switch_button_color
        else:
            curr_botton_color = def_button_color
        queue_redraw() # Redraw after changing color
