@tool

extends Node2D

const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")

@onready var main_color: Color = Color.CORAL
@onready var star_points: PackedVector2Array
@onready var outline_points: PackedVector2Array
@onready var outline_width: float = 5.0
@onready var star_outer_rad: float = 50
@onready var star_inner_rad: float = 25
@onready var num_points: int = 5
@onready var angle_deg: float = 0

func _ready() -> void:
    queue_redraw()

func _draw() -> void:
    ## Forming the shape
    star_points = StarGenerator.get_star_points(num_points, star_outer_rad, star_inner_rad, Vector2.ZERO, angle_deg) # Main body
    outline_points = StarGenerator.get_star_points(num_points, star_outer_rad, star_inner_rad, Vector2.ZERO, angle_deg) # Outline
    
    # Drawing the shapes:
    draw_polygon(star_points, [main_color]) # Main Body
