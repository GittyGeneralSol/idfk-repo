@tool

extends CanvasLayer

@onready var platform_name: String
@onready var hexagonal_buttons: Control = $HexagonalButtons

func _ready() -> void:
    pass

func on_viewport_size_change():
    update_hex_buttons()
    
func update_hex_buttons():
    var viewport_size = get_viewport().size
    var y_pos = viewport_size.y - viewport_size.y/10
    hexagonal_buttons.global_position = Vector2(viewport_size.x/2, y_pos)
