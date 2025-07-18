@tool

extends Node2D

const COLORED_RECT = preload("res://scenes/effects/colored_rect.tscn")

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

# --- Appearance Parameters --
@export var rect_height: float = 40
@export var rect_width: float = 40
@export var max_size_variation: Vector2 = Vector2(20, 20)
@export var max_displ: Vector2 = Vector2(350, 350)
@export var outline_width: float = 0.0
@export var rect_col: Color = Color.CHARTREUSE
@export var number_of_rects: int = randi_range(6, 10)

func _ready() -> void:
    _setup_rects()

func _setup_rects() -> void:
    for i in number_of_rects:
        # Draw a rect:
        var displacement = Vector2(randi_range(-max_displ.x/2, max_displ.x/2), randi_range(-max_displ.y/2, max_displ.y/2))
        var width = rect_width + randi_range(-max_size_variation.x/2, max_size_variation.x/2)
        var height = rect_height + randi_range(-max_size_variation.y/2, max_size_variation.y/2)
        
        var current_rect = COLORED_RECT.instantiate()
        current_rect.outline_width = outline_width
        current_rect.target_displ = displacement
        current_rect.target_rect_width = width
        current_rect.target_rect_height = height
        current_rect.rect_col = rect_col
        
        add_child(current_rect)
