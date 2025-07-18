@tool

extends Node2D

@export var effect_radius: PackedScene = preload("res://scenes/turrets/radii/blue_radius.tscn")
@export var turret_on: bool = true
@onready var core: Node2D = $body/core
@onready var energy_pulse: Node2D = $body/energy_pulse

func _ready() -> void:
    create_radius()
    
func _process(delta: float) -> void:
    if turret_on: rotation_degrees = fmod(rotation_degrees + 1, 360)
    
func create_radius():
    if effect_radius and turret_on:
        var current_effect_radius = effect_radius.instantiate()
        current_effect_radius.z_index = 15
        add_child(current_effect_radius)
        
func toggle_turret():
    ## ON / OFF:
    var darker_col = Color.AQUA.darkened(0.3)
    if turret_on:
        turret_on = false
        energy_pulse.set_color(darker_col)
        core.set_color(darker_col)
        if get_radius():
            get_radius().toggle_radius(false)
    else:
        turret_on = true
        energy_pulse.set_color(Color.AQUA)
        core.set_color(Color.AQUA)
        energy_pulse.tween_scale_to_max()
        if get_radius():
            get_radius().toggle_radius(true)

    energy_pulse.turret_on = turret_on
    core.turret_on = turret_on
    
func get_radius() -> Node:
    if has_node("BlueRadius"):
        return get_node("BlueRadius")
    else: return null
