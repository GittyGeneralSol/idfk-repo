extends Node2D

class_name Void

signal world_positions_updated
        
func _ready() -> void:
    # Connect Signals
    WorldUtils.world_created.connect(Callable(self, "on_the_creation_of_a_world"))
    WorldUtils.world_deleted.connect(Callable(self, "on_the_deletion_of_a_world"))
    TransportManager._player_transported.connect(Callable(self, "on_player_transport"))

    update_world_positions()
    
func on_the_creation_of_a_world(world_name: String, world_node: World, caller: Node):
    print("VOID - WORLD '", world_node, "' WITH WORLD_NAME '", world_name, "' WAS JUST CREATED. NODE WHICH CALLED FOR THE CREATION OF THIS WORLD: ", caller)
    update_world_positions()
    
func on_the_deletion_of_a_world(world_name: String, world_node: World, caller: Node):
    print("VOID - WORLD '", world_node, "' WITH WORLD_NAME '", world_name, "' WAS JUST DELETED.")
    update_world_positions()

func on_player_transport(_target_world: World, _target_world_name: String):
    print("VOID - PLAYER JUST GOT TRANSPORTED TO WORLD '", _target_world, "' WITH WORLD_NAME '", _target_world_name, "'.")
    
func update_world_positions() -> void:
    await get_tree().process_frame # Wait a frame to let queue_free finish
    
    var worlds = WorldUtils.get_worlds_by_void()

    var counter = 0.0
    for world in worlds:
        world.global_position.x = counter * 8000.0
        world.global_position.y = 0.0
        counter += 1
    world_positions_updated.emit()
        
func _remove_world(world: World, caller: Node):
    WorldUtils.emit_signal("world_deleted", world.world_name, world, caller)
    world.call_deferred("remove_from_group", "worlds")
    world.call_deferred("queue_free")
        
func _create_and_get_world(world_name: String) -> Node:
    var WORLD = load("res://scenes/worlds/" + world_name + ".tscn") # Check in files
    var world = WORLD.instantiate()
    
    world.call_deferred("add_child", world)

    return world
        
