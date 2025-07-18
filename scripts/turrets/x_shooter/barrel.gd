extends GunOne

func _ready() -> void:
    set_values()
    super._ready()
    
func set_values():
    enemy_groups = ["deltsqus", "player"]
