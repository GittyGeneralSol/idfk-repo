@tool

extends Node2D

const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")

@onready var main_body = get_parent().get_child(0)
@onready var deco_points: PackedVector2Array
@onready var deco_width: float = (star_outer_rad - star_inner_rad)/2
@onready var star_outer_rad: float = main_body.star_outer_rad
@onready var star_inner_rad: float = main_body.star_inner_rad
@onready var num_points: int = main_body.num_points
@onready var angle_deg: float = main_body.angle_deg
@onready var scaling_factor: float = 1.0

func _ready() -> void:
    scaling_factor = 0.9
    scale = main_body.scale * scaling_factor
    queue_redraw()

func _draw() -> void:
    ## Forming the shape
    deco_points = StarGenerator.get_star_points(num_points, star_outer_rad, star_inner_rad, Vector2.ZERO, angle_deg) # Deco
    
    # Adding an extra point to array to form a closed shape:
    var extra_point = deco_points[0] # First point from array
    deco_points.append(extra_point)
    
    # Drawing the shapes:
    draw_polyline(deco_points, Color.CHOCOLATE, 4, true)
