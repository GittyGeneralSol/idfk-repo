@tool

extends Block

@export var turret_name: String = "":
    set(v): turret_name = v; create_turret()

# -- Store Turret -- 
var turret: Node2D

func _ready() -> void:
    b_setup_variables("turret_base", _worldly_position)
    update_stored_data()
    create_turret()
        
func create_turret():
    if not turret_name: 
        return
    
    var turret = get_turret()
    if turret:
        turret.queue_free()
    
    var TURRET = load("res://scenes/turrets/" + turret_name + ".tscn")
    turret = TURRET.instantiate()
    
    turret.z_index = 15
    add_child(turret)
    
func get_turret() -> Node:
    return turret
    
func update_stored_data():
    var temp_dict: Dictionary
    temp_dict = {
        "turret_name": turret_name
    }
    stored_data = temp_dict
