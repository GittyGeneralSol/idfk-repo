extends Node
class_name CreatureBlinker

signal blink_end
signal blink_start

var DEBUG_PREFIX: String
var _blinking_info: Dictionary # Main Data Object
var _owner: Node2D
var _current_behavior_loop: Variant # To hold the Callable for the running loop
var _timer: SceneTreeTimer
var _blinking: bool = false
var _children_left_to_blink

func _init(owner_node: Node2D, blinking_info: Dictionary):
    _owner = owner_node
    _blinking_info = blinking_info
    DEBUG_PREFIX = _owner.name + " Blinker-Logic: "

# --- Public Methods to Start Behaviors ---

func start_by_name(method_name: String = "_standard_behavior_loop"):
    method_name = _blinking_info.get("blink_loop", "_standard_behavior_loop")
    match(method_name):
        "standard": start_standard_behavior()
        "ranged": start_ranged_behavior()
        _: pass

func start_standard_behavior():
    _current_behavior_loop = Callable(self, "_standard_behavior_loop")
    _current_behavior_loop.call()

func start_ranged_behavior():
    _current_behavior_loop = Callable(self, "_ranged_behavior_loop")
    _current_behavior_loop.call()
    
func start_timer(time: float):
    if is_instance_valid(_timer):
        _timer = null # Free the previous timer resource.
        
    _timer = _owner.get_tree().create_timer(time)
    await _timer.timeout

func stop_behavior():
    _current_behavior_loop = null # This effectively stops the loops
    
func stop_blinking():
    _blinking = false
    
    var eyeish_children = _owner.get_eyeish_children()
    if eyeish_children.is_empty():
        return
    for child in eyeish_children:
        if child.has_method("stop_blinking"):
            child.stop_blinking()
            
    blink_end.emit(_owner)
    
# --- The Actual Behavior Logic ---

func _standard_behavior_loop():
    # Check if we should still be running this loop
    if _current_behavior_loop != Callable(self, "_standard_behavior_loop"):
        return
        
    while is_instance_valid(_owner):    
        if _owner.is_dead():
            return 
        var interval = _blinking_info.get("interval", 4.0)
        await start_timer(interval)
        await blink()
        
        # Check again in case the behavior was changed while we were awaiting
        if _current_behavior_loop != Callable(self, "_standard_behavior_loop"):
            return
            
func _ranged_behavior_loop():
    # Check if we should still be running this loop
    if _current_behavior_loop != Callable(self, "_ranged_behavior_loop"):
        return
        
    while is_instance_valid(_owner):    
        if _owner.is_dead():
            return 
        var min = _blinking_info.get("min_interval", 3.0)
        var max = _blinking_info.get("max_interval", 4.0)
        await start_timer(randf_range(min, max))
        await blink()
        
        # Check again in case the behavior was changed while we were awaiting
        if _current_behavior_loop != Callable(self, "_ranged_behavior_loop"):
            return

# This is a public method the CreatureAI or a timer will call.
func blink():
    if not is_instance_valid(_owner):
        return
    
    if _blinking: return # Prevent interruption
    
    _blinking = true
    blink_start.emit()
    
    var eyeish_children = _owner.get_eyeish_children()
    if eyeish_children.is_empty():
        # If there are no children, we are done immediately.
        blink_end.emit()
        _blinking = false
        return
    
    # Count the number of children left
    _children_left_to_blink = eyeish_children.size()
    
    for child: BaseCreaturePart in eyeish_children:
        child.blinked.connect(Callable(self, "_on_child_blinked"), CONNECT_ONE_SHOT)
        child.blink()
    
# Blink completion handled by this helper
func _on_child_blinked():
    _children_left_to_blink -= 1
    # When the last child has blinked, emit the completion signal
    if _children_left_to_blink == 0:
        blink_end.emit()
        _blinking = false
