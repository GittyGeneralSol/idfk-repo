extends Node2D

func get_parent_world() -> Node:
    return WorldUtils.get_parent_world(get_parent().get_parent())
