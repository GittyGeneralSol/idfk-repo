extends BaseCreature

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    set_eyesqu_params()
    
func set_eyesqu_params():
    var new_blinking_info: Dictionary = {
        "blink_loop": "ranged",
        "min_interval": 2.0,
        "max_interval": 4.0
    }
    
    var new_movement_info: Dictionary = {
        "move_type": CreatureMover.MoveType.SQUISH,
        "aftermove_delay": 0.8
    }
    
    # Duplicate any existing parameters that may have been set externally in initializaton phase
    var creature_params = params.duplicate()
    creature_params["creature_type"] = "eyesqu"
    creature_params["max_hp"] = 100
    creature_params["hp"] = 100
    creature_params["movement_info"] = new_movement_info
    creature_params["blinking_info"] = new_blinking_info
    update_from_params(creature_params)
    
func _on_initial_move_trigger_timeout() -> void:
    if !dead: _ai_logic.start_astar_behavior(WorldUtils.get_player_node())
