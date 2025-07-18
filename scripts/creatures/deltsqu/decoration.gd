@tool

extends Node2D

const StarGenerator = preload("res://scripts/shape_generators/StarGenerator.gd")

@export var star_points: PackedVector2Array
@export var star_outer_rad: float = 40
@export var star_inner_rad: float = 12
@export var num_points: int = 3
@export var angle_deg: float = -90
@export var deco_color: Color = Color("b70073")

func _draw() -> void:
    star_points = StarGenerator.get_star_points(num_points, star_outer_rad, star_inner_rad, Vector2.ZERO, angle_deg)
    draw_polygon(star_points, [deco_color])
