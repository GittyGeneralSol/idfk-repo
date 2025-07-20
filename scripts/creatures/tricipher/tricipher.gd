extends BaseCreature

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    set_tricipher_params()
    print(name.capitalize() + " HP: ", get_hp())
    
func set_tricipher_params():
    z_index = 1100
    
    var new_blinking_info: Dictionary = {
        "blink_loop": "ranged",
        "min_interval": 2.0,
        "max_interval": 4.0
    }
    
    var new_movement_info: Dictionary = {
        "move_type": CreatureMover.MoveType.SLIDE,
        "aftermove_delay": 0.1
    }
    
    var new_animation_info: Array[Dictionary] = [
        {
            "animation": "tricipher/swing_self_pingpong",
            "custom_blend": -1,
            "custom_speed": 1.0,
            "start_delay": 0.0
        }, 
        {
            "animation": "tricipher/hat_swing",
            "custom_blend": -1,
            "custom_speed": 1.0,
            "start_delay": 0.5
        }
    ]
    
    # Duplicate any existing parameters that may have been set externally in initializaton phase
    var creature_params = params.duplicate()
    creature_params["creature_type"] = "tricipher"
    creature_params["max_hp"] = 60 * pow(10, 6)
    creature_params["hp"] = 60 * pow(10, 6)
    creature_params["movement_info"] = new_movement_info
    creature_params["blinking_info"] = new_blinking_info
    creature_params["animation_info"] = new_animation_info
    update_from_params(creature_params)
    
func _on_initial_move_trigger_timeout() -> void:
    if !dead: _ai_logic.start_astar_behavior(WorldUtils.get_player_node())
