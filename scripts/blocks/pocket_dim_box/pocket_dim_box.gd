extends Block

# --- (Exports and @onready variables are all fine) ---
@export var target_world_name: String
@onready var text_rect: Node2D = $layers/text_rect
@onready var reflection_container: SubViewportContainer = $Container/SelfReflectionContainer
@onready var reflection_viewport: SubViewport = $Container/SelfReflectionContainer/SubViewport
@onready var reflection_camera: WorldlyCamera = $Container/SelfReflectionContainer/SubViewport/WorldlyCamera
@export var reflection_camera_zoom: float = 1.0
@export var reflection_camera_offset: Vector2 = Vector2.ZERO
@export var parent_world: World

# --- State Machine Variables ---
var _is_updating: bool = false
var _needs_update: bool = false

func _ready() -> void:
    parent_world = WorldUtils.get_parent_world(self)
    b_setup_variables("pocket_dim_box", _worldly_position, "pocket_dim_data")
    update_stored_data() # Update data once at start

    if Engine.is_editor_hint():
        return
    
    # --- Connect to specific, meaningful game events ---
    # Use call_deferred to ensure we don't start the update process
    # until the current frame's physics/logic is complete.
    var the_void: Void = WorldUtils.get_void()
    the_void.world_positions_updated.connect(Callable(self, "on_world_positions_changing"))
    TransportManager._player_transported.connect(Callable(self, "on_player_transport"))

    # Initial update call
    queue_update()

func on_world_positions_changing():
    queue_update()
    
func on_player_transport(_target_world: World, _target_world_name: String):
    queue_update()

func _establish_two_way_reference(source_world: Node, target_world: Node):
    if not is_instance_valid(source_world) or not is_instance_valid(target_world):
        return

    # Update source world to reference target
    if not source_world.world_refs.has(target_world.world_name):
        source_world.world_refs.append(target_world.world_name)
        
    # Update target world to know that it is being observed by source
    if not target_world.observer_worlds.has(source_world.world_name):
        target_world.observer_worlds.append(source_world.world_name)

# This gatekeeper decides IF and WHEN to start the real async update.
func queue_update():
    if not parent_world:
        return
    
    # Mark that an update is needed.
    _needs_update = true
    var parent_world_name: String = parent_world.world_name
    var primary_observers: PackedStringArray = parent_world.observer_worlds
    var player_world: World = WorldUtils.get_parent_world(WorldUtils.get_player_node())
    var player_world_name = player_world.world_name
    print("PDB - (queue_update) - PARENT_WORLD: " + parent_world_name.to_upper() + " - PARENT_WORLD'S PRIMARY OBSERVERS: ", primary_observers, " - TARGET_WORLD: " + target_world_name + " - PLAYER_WORLD: " + player_world_name + " - _needs_update set to true. Value of (should_display_target) = ", should_display_target())
    
    # If an update is already running, do nothing more.
    # The running update will handle this new request when it's done.
    if _is_updating:
        return

    # If we get here, no update is running, so we can start one.
    _is_updating = true
    
    # We don't await this. We fire it off and let it run in the background.
    _run_update_logic()

# This is the real, protected async function.
# It will only ever have one instance of itself running at a time.
func _run_update_logic():
    # Loop until no more updates are queued.
    while _needs_update:
        _needs_update = false
        
        # --- 1. Gather State & Pre-Checks ---
        var parent_world = WorldUtils.get_parent_world(self)
        if not is_instance_valid(parent_world):
            continue

        var should_render_now = should_display_target()

        # --- 2. Core World & Reference Logic --
        var target_world: World = null
        if should_render_now: # If to render.. create/get world
            target_world = await WorldUtils.request_world(target_world_name, self) # Only create world if should display returns true
        
        if not target_world: # World may already exist. Get if possible, EVEN IF not to display. 
            target_world = WorldUtils.get_world_by_void(target_world_name)
        
        # Always establish the reference to prevent deadlocks.
        _establish_two_way_reference(parent_world, target_world)
        
        if not is_instance_valid(target_world):
            continue # Skip this iteration

        # --- 3. Display Logic ---
        if not should_render_now:
            reflection_container.visible = false
            continue

        # Await a frame for transforms to be calculated.
        await get_tree().process_frame

        # Final safety check in case the world was deleted during the await.
        if not is_instance_valid(target_world):
            continue
            
        _setup_reflection_display(target_world)

    # All updates are done. Release the lock.
    _is_updating = false

# --- Helper functions (mostly unchanged) ---

func _setup_reflection_display(target_world: Node):
    # This function is fine. It's now guaranteed to receive a valid node.
    reflection_viewport.world_2d = get_tree().root.get_viewport().get_world_2d()
    reflection_viewport.size = Vector2(1420, 1420)
    reflection_camera.global_position = target_world.global_position + reflection_camera_offset
    reflection_camera.zoom = Vector2(reflection_camera_zoom, reflection_camera_zoom)
    reflection_container.visible = true
    reflection_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    
# Check whether parent world of this PDB is the secondary reference of player world or not (2-deep observance)
func should_display_target() -> bool:
    # Abort if target_world_name is not given
    if not target_world_name:
        set_viewport_active(false)
        return false
    
    var parent_world: World = WorldUtils.get_parent_world(self)
    var player_node = WorldUtils.get_player_node()
    
    # Abort if player is null or PDB is outside of world
    if not is_instance_valid(player_node) or not is_instance_valid(parent_world):
        set_viewport_active(false)
        return false
    
    var player_world: World = WorldUtils.get_parent_world(player_node)
    var player_world_name = player_world.world_name
    
    # Check 1: Whether parent world is target world
    if parent_world.world_name == player_world_name:
        set_viewport_active(true)
        return true
    else:
        set_viewport_active(false)
        return false
    
    #var primary_observers: PackedStringArray = parent_world.observer_worlds
    
    # Check 2: Whether player world is a primary observer
    #if primary_observers.has(player_world_name):
        #return true
    #else: return false
    
    ## WARNING Secondary Check is not wanted
    
    # If here, do check the secondary observers
    # return secondary_observance_check(primary_observers, player_world_name)

func set_viewport_active(active: bool):
    # Enable/disable processing of the viewport
    reflection_viewport.set_process_mode(SubViewport.PROCESS_MODE_PAUSABLE if active else Node.PROCESS_MODE_DISABLED)

func secondary_observance_check(primary_observers: PackedStringArray, player_world_name: String) -> bool:
    # Find secondary observers if here
    var secondary_observers: PackedStringArray
    for observer_name in primary_observers:
        var observer_world = WorldUtils.get_world_by_void(observer_name)
        
        # Skip this iteration if world is null:
        if not is_instance_valid(observer_world):
            continue
        
        secondary_observers += observer_world.observer_worlds
        
    # Check 3: Check if the list of secondary_observers has player world's name in it
    if secondary_observers.has(player_world_name):
        return true
    else:
        return false # If all checks failed, return false.
    
func update_stored_data():
    var temp_dict: Dictionary
    temp_dict = {
        "target_world_name": target_world_name
    }
    stored_data = temp_dict
