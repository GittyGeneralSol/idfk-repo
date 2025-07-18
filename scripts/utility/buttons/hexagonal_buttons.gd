@tool

extends Control

@onready var build_button: PolygonButton = $"../Control/BuildButton"
@onready var destroy_button: PolygonButton = $"../Control2/DestroyButton"

func _ready() -> void:
    #build_button.position = Vector2(30 , 17)
    #destroy_button.position = Vector2(-31, -18)
    connect_button(build_button)
    connect_button(destroy_button)

func connect_button(current_button: Node) -> bool:
    if not current_button:
        return false
    
    ## Connect the current_button's signals to this node's on_button_downed and release function:
    current_button.connect("button_downed", Callable(self, "on_button_down"))
    current_button.connect("button_released", Callable(self, "on_button_release"))
    current_button.connect("button_press_canceled", Callable(self, "on_button_press_cancellation"))
    
    return true
    
func on_button_down(action_string: String):
    pass
    
func on_button_release(action_string: String):
    var player_node = WorldUtils.get_player_node()
    var player_world: World = WorldUtils.get_parent_world(player_node)
    
    if not is_instance_valid(player_world):
        return
    
    match(action_string):
        "build_button":
            if Vars.destroy_mode:
                Vars.destroy_mode = false
                
            # If already on, turn off instead.
            if Vars.build_mode:
                Vars.build_mode = false
                player_world.handle_selector()
                return
            
            Vars.build_mode = true
            player_world.handle_selector()
                
        "destroy_button":           
            if Vars.build_mode:
                Vars.build_mode = false
                
            # If already on, turn off instead.
            if Vars.destroy_mode:
                Vars.destroy_mode = false
                player_world.handle_selector()
                return
            
            Vars.destroy_mode = true
            player_world.handle_selector()
            
func on_button_press_cancellation(action_string: String):
    pass
    
