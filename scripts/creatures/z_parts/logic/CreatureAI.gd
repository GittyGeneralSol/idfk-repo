extends RefCounted
class_name CreatureAI

# A-Star
const REPLAN_DISTANCE_THRESHOLD: float = 1

var DEBUG_PREFIX: String
var _ai_info: Dictionary # Main Data Object
var _owner: BaseCreature
var _mover: CreatureMover
var _target_object: Node = null
var _current_behavior_loop: Variant # To hold the Callable for the running loop

func _init(owner_node: Node2D, mover_logic: CreatureMover, new_ai_info: Dictionary = {}):
    _owner = owner_node
    _mover = mover_logic
    DEBUG_PREFIX = _owner.name + " AI-Logic: "
    
    _ai_info = new_ai_info

# --- Public Methods to Start Behaviors ---

func start_by_name(method_name: String = "random"):
    method_name = _ai_info.get("behavior_loop", "random")
    match(method_name):
        "random": start_standard_behavior()
        "pathfinding": start_astar_behavior(_ai_info.get("target", null))
        "none": stop_behavior()
        _: start_standard_behavior()

func start_standard_behavior():
    _current_behavior_loop = Callable(self, "_standard_behavior_loop")
    _current_behavior_loop.call()

func start_astar_behavior(target: Node = null):
    _target_object = target
    _current_behavior_loop = Callable(self, "_astar_behavior_loop")
    _current_behavior_loop.call()

func stop_behavior():
    _target_object = null
    _current_behavior_loop = null # This effectively stops the loops
    
# --- The Actual Behavior Logic ---

# A safer, clearer version of the standard behavior loop
func _standard_behavior_loop():
    # Check if we should still be running this loop
    if _current_behavior_loop != Callable(self, "_standard_behavior_loop"):
        return
        
    while is_instance_valid(_owner):    
        if not _owner.is_able_to_move():
            return
            
        var _move_delay: float
        if "move_delay" in _owner:
            _move_delay = _owner.get("move_delay")
        else: _move_delay = 1.0
            
        var random_move_numb = randi_range(1,5)
        match(random_move_numb):
            1: _mover.execute_action("move_squish", { "direction": Vector2.UP }, _move_delay)
            2: _mover.execute_action("move_squish", { "direction": Vector2.DOWN }, _move_delay)
            3: _mover.execute_action("move_squish", { "direction": Vector2.LEFT }, _move_delay)
            4: _mover.execute_action("move_squish", { "direction": Vector2.RIGHT }, _move_delay)
            5: _mover.execute_action("idle", { "idle_time": 8.0 }) # Renamed param for clarity
        
        await _mover.action_finished
        
        # Check again in case the behavior was changed while we were awaiting
        if _current_behavior_loop != Callable(self, "_standard_behavior_loop"):
            return
            
func _astar_behavior_loop():
    if _current_behavior_loop != Callable(self, "_astar_behavior_loop"):
        return

    while is_instance_valid(_owner):    
        # Re-check ability to move
        if not _owner.is_able_to_move(): 
            return
        
        # Get & Execute Path
        var path: PackedVector2Array = await _plan_path()
        if not path.is_empty():
            await _execute_path(path)
        
        # Brief pause
        _mover.execute_action("idle", { "idle_time": 0.1 })
        await _mover.action_finished
        
        if _current_behavior_loop != Callable(self, "_astar_behavior_loop"):
            return

#region --- AStar Pathfinding Logic ---

# --- Planning Phase ---

func _plan_path() -> PackedVector2Array:
    # Get a valid target position.
    var target_pos: Vector2 = _get_target_position()
    
    # Check if we're already there.
    if target_pos == _owner.get_grid_pos():
        _mover.execute_action("idle", { "idle_time": 2.0 })
        await _mover.action_finished
        return []

    # Find the path using A* by calling the owner's helper.
    var path: PackedVector2Array = get_path_steps(_owner.get_grid_pos(), target_pos)
    if path.is_empty(): # Pathfinding failed.
        # print("Pathfinding failed, idling.")
        _mover.execute_action("idle", { "idle_time": 0.5 })
        await _mover.action_finished
        return []
    
    return path
    
func get_path_steps(beg_grid_pos: Vector2i, target_grid_pos: Vector2i) -> PackedVector2Array:
    var astar_grid = WorldUtils.get_parent_world_astar_grid(_owner)
    
    var parent_world: World =  WorldUtils.get_parent_world(_owner)
    if not is_instance_valid(parent_world):
        return []
    
    if not astar_grid:
        return []
        
    if not (WorldUtils.pos_is_inside_rect(target_grid_pos,  parent_world.world_size)):
        return []
        
    if not (astar_grid.is_in_bounds(target_grid_pos.x, target_grid_pos.y) and (astar_grid.is_in_bounds(beg_grid_pos.x, beg_grid_pos.y))):
        return []

    
    if astar_grid.is_point_solid(target_grid_pos):
        return []
        
    var series_of_steps = astar_grid.get_id_path(beg_grid_pos, target_grid_pos)
    return series_of_steps

# --- Execution Phase ---

func _execute_path(path: PackedVector2Array):
    if path.is_empty(): return
    
    # The final destination of our currently calculated path.
    var planned_destination = path[path.size() - 1]
    
    # Iterate through each segment of the path.
    # We start from index 1 because path[0] is the starting position.
    for i in range(1, path.size()):
        if not _owner.is_able_to_move(): 
            return
        
        var start_point = _owner.get_grid_pos()
        var end_point = path[i]
        
        # Execute the moves for this single horizontal or vertical segment.
        var result: String = await _execute_path_segment(start_point, end_point, planned_destination)
        
        # If any segment fails, abort this path and let the main loop re-plan.
        if result == "failed":
            print(DEBUG_PREFIX + "Path execution failed. Re-planning.")
            _mover.execute_action("idle", { "idle_time": 0.5 })
            await _mover.action_finished
            return
            
        if result == "target_moved":
            print(DEBUG_PREFIX + "Target Moved. Aborting current path to re-plan.")
            return
            
func has_target_moved(original_target: Vector2) -> bool:
    if is_instance_valid(_target_object):
        var current_target_pos = _target_object.get_grid_pos()
        if current_target_pos.distance_to(original_target) > REPLAN_DISTANCE_THRESHOLD:
            return true # Abort this path. The main loop will take over.
    return false

func _execute_path_segment(start_pos: Vector2, end_pos: Vector2, final_dest: Vector2) -> String:
    var delta: Vector2 = end_pos - start_pos
    var move_dir: Vector2
    var num_steps: int

    # A-star paths should only be cardinal.
    if delta.x != 0:
        move_dir = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
        num_steps = absi(delta.x)
    elif delta.y != 0:
        move_dir = Vector2.DOWN if delta.y > 0 else Vector2.UP
        num_steps = absi(delta.y)
    else:
        printerr(DEBUG_PREFIX + "Path contains invalid zero-length segment.")
        return "failed" # Signal failure

    ## Execute the individual tile-by-tile moves.
    for i in range(num_steps):
        # Target Node (if existent) Position Check
        var target_moved: bool = has_target_moved(final_dest)
        if target_moved:
            return "target_moved"
            
        # Await the result of the step.
        var success: bool = await execute_individual_step(move_dir)
        
        # If ANY step fails, immediately stop and return false.
        if not success:
            return "failed"
            
    # If the loop completes without any step failing, the segment was successful.
    return "success"
    
func execute_individual_step(move_dir: Vector2) -> bool:
    if not _owner.is_able_to_move(): 
        return false
            
    var pos_before_move = _owner.get_grid_pos()
    
    # Tell the mover to execute one step.
    _mover.move(move_dir)
    await _mover.action_finished
    
    # Check if we got stuck after the move.
    if _owner.get_grid_pos() == pos_before_move:
        print(DEBUG_PREFIX + "Creature got stuck mid-path.")
        return false # Signal failure
        
    return true # Signify success

# --- Helper Functions ---

func _get_target_position() -> Vector2:
    # If we have a valid target object (like the player), return its position.
    if is_instance_valid(_target_object):
        # Assumes the target has a 'grid_pos' property or a get_grid_pos() method.
        if _target_object.has_method("get_grid_pos"):
            return _target_object.get_grid_pos()
        elif _target_object.has("grid_pos"):
             return _target_object.grid_pos

    # --- No target, so find a random position ---
    # Get world info from the owner.
    var world = _owner.get_parent_world()
    var world_bounds = world.world_size / 2.0
    var effective_bounds = world_bounds - Vector2.ONE
    var step_range = clamp(Vector2(10, 10), -effective_bounds, effective_bounds)

    var move_x = randi_range(-step_range.x, step_range.x)
    var move_y = randi_range(-step_range.y, step_range.y)
    
    # Get current position from owner.
    var target_pos = _owner.get_grid_pos() + Vector2(move_x, move_y)
    
    # Clamp the position to be within the world bounds.
    target_pos.x = clamp(target_pos.x, -effective_bounds.x, effective_bounds.x)
    target_pos.y = clamp(target_pos.y, -effective_bounds.y, effective_bounds.y)
    
    return target_pos

#endregion
