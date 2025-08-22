extends BaseCreature

@onready var body: Node2D = $body
@onready var eyes_container: BaseCreatureEyeContainer = $eyes_container
@onready var eyelids_left: Node2D = $eyes/left_eye/eyelids_left
@onready var eyelids_right: Node2D = $eyes/right_eye/eyelids_right

@onready var blink_trigger: Timer = $Blink_trigger
@onready var move_cooldown: Timer = $move_cooldown

@export var speed_factor: float = 1.0
@export var aftermove_cooldown: float = 0.2 # How long to pause AFTER move has been completed
@onready var move_duration = 0.2 ## How long the move lasts.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    set_player_params()
    load_saved_player()
    WorldUtils.set_current_player_world(self)
    form_and_save_creature("The player. Polygon master. The grey square blob. Just an imitation of something else..")
    
    var data = {
        "yo": "no",
        "car_color": Color.AQUA,
        "KILL?": false,
        "size": Vector2(5, 25)
    }
    
    SaveManager.save_data_to_file(data, "TEST_FILE", "osama/bin/test_path/")

func set_player_params():
    var new_blinking_info: Dictionary = {
        "blink_loop": "standard",
        "interval": 4.0
    }
    
    var new_movement_info: Dictionary = {
        "move_type": CreatureMover.MoveType.SQUISH,
        "aftermove_delay": 0.2
    }
    
    var new_ai_info: Dictionary = {
        "behavior_loop": "none"
    }
    
    # Duplicate any existing parameters that may have been set externally in initializaton phase
    var creature_params = params.duplicate()
    creature_params["creature_type"] = "player"
    creature_params["max_hp"] = 100
    creature_params["hp"] = 100
    creature_params["ai_info"] = new_ai_info
    creature_params["movement_info"] = new_movement_info
    creature_params["blinking_info"] = new_blinking_info
    update_from_params(creature_params)

func load_saved_player():
    # Load player data and apply it.
    
    var world_0_created: bool = false
    
    # Only apply player data AFTER World 0's creation
    while not world_0_created:
        var args = await WorldUtils.world_created
        if args[0] == "world_0":
            SaveManager._load_and_apply_player_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:   
    #print("is_able_to_move(): ", is_able_to_move(), ", action_lock: ", action_lock)
    
    var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    # Multi Input check
    if input_dir.x != 0 and input_dir.y != 0:
        input_dir.y = 0
    #print(input_dir)
    
    if input_dir != Vector2.ZERO:
        await handle_move_input(input_dir)

func _on_blink_trigger_timeout() -> void:
    if !dead: eyes_container.blink() # Trigger a blink

## Called by MobileTapMove
func attempt_move_step(dir_vector: Vector2):   
    await handle_move_input(dir_vector)

# New central function
func handle_move_input(dir: Vector2):
    if not is_able_to_move():
        return
        
    await _action_logic.move(dir)
    
func on_button_release(action_string: String):
    print("\nPLAYER: Button with action_string '", action_string, "' just got released!")
