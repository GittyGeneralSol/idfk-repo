extends Node
class_name CameraHandler

var camera: WorldlyCamera
@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.01 # 0.3
@export var max_zoom: float = 10.0
@export var smoothing_speed: float = 10.0
@export var edge_buffer: float = 0.0  # Buffer from room edges
@export var player_exists: bool = false
@export var target: Node

## Mobile:
var _is_mobile_platform: bool = true  # Set this in your _ready() based on OS.get_name()


func _ready() -> void:
    camera = WorldlyCamera.new()
    add_child(camera)
    if WorldUtils.is_in_player_world(self): camera.make_current()

func _process(delta: float) -> void:
    if not WorldUtils.get_player_node(self):
        return
    
    if WorldUtils.is_in_player_world(self): camera.make_current()
    
    target = WorldUtils.get_player_node(self)
    
    if target and WorldUtils.is_in_player_world(self):
        var ts = Constants.tile_size 
        var world_size_pixels = get_parent().world_size * ts
        
        # Set camera limits
        var limit_left = -world_size_pixels.x / 2 - ts
        var limit_top = -world_size_pixels.y / 2 - ts
        var limit_right = world_size_pixels.x / 2 + ts
        var limit_bottom = world_size_pixels.y / 2 + ts
        
        var target_pos = target._worldly_position
        var new_pos = camera._worldly_position.lerp(target_pos,  smoothing_speed * delta)
        
        # Clamp camera position within room bounds
        new_pos.x = clamp(new_pos.x, limit_left + edge_buffer, limit_right - edge_buffer)
        new_pos.y = clamp(new_pos.y, limit_top + edge_buffer, limit_bottom - edge_buffer)
        
        camera._worldly_position = new_pos
    
    elif !target and WorldUtils.is_in_player_world(self):   
        var input_dir = Vector2.ZERO
        if Input.is_action_pressed("move_right"):
            input_dir.x += (1 * (1 / camera.zoom.x))
        if Input.is_action_pressed("move_left"):
            input_dir.x -= (1 * (1 / camera.zoom.x))
        if Input.is_action_pressed("move_down"):
            input_dir.y += (1 * (1 / camera.zoom.x))
        if Input.is_action_pressed("move_up"):
            input_dir.y -= (1 * (1 / camera.zoom.x))
    
        input_dir = input_dir.normalized()
        camera.position += input_dir * move_speed * delta

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and WorldUtils.is_in_player_world(self):
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_camera(-zoom_speed)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_camera(zoom_speed)
            
    var zoom_speed_mobile = zoom_speed

    # Mobile Pinch-to-Zoom Logic
    if _is_mobile_platform and event is InputEventMagnifyGesture and WorldUtils.is_in_player_world(self):
        Vars.pinching_screen = true
        var base_zoom = camera.zoom.x
        var factor = event.factor
        var zoom_change = base_zoom * (factor - 1.0)
        zoom_camera(zoom_change)
    else: Vars.pinching_screen = false

func zoom_camera(zoom_factor: float) -> void:
    var new_zoom = camera.zoom.x + zoom_factor
    new_zoom = clampf(new_zoom, min_zoom, max_zoom)
    camera.zoom = Vector2(new_zoom, new_zoom)
    Vars.camera_zoom = camera.zoom.x
