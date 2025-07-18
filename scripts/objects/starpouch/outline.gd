@tool

extends Node2D

const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")

@onready var main_body = get_parent().get_child(0)
@onready var star_points: PackedVector2Array
@onready var outline_width: float = main_body.outline_width
@onready var star_outer_rad: float = main_body.star_outer_rad
@onready var star_inner_rad: float = main_body.star_inner_rad
@onready var num_points: int = main_body.num_points
@onready var angle_deg: float = main_body.angle_deg
@onready var scaling_factor: float = 1.0

func _ready() -> void:
    scaling_factor = 1 + outline_width * 1.5 / star_inner_rad
    scale = main_body.scale * scaling_factor
    queue_redraw()
    
func _draw() -> void:
    ## Forming the shape
    star_points = StarGenerator.get_star_points(num_points, star_outer_rad, star_inner_rad, Vector2.ZERO, angle_deg) # Outline
    
    # Drawing the shapes:
    draw_polygon(star_points, [Color.BLACK]) # Outline Body
