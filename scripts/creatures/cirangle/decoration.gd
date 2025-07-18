@tool

extends Node2D

@export var triangle_size: float = 15
@export var triangle_color1: Color = Color.ORANGE
@export var triangle_color2: Color = Color.ORANGE
@export var triangle_h_offset: int = 50 # Distance each triangle will go away from the other horizontally
@export var triangle_v_offset: int = 35 # Distance each triangle will go away from the other vertically
@export var displacement: Vector2 = Vector2(0, 0) # Diplacement of the whole deco system (horizontally)
@onready var rotation_angle: float = 0.0

func _ready() -> void:
    print("Deco: ", global_position)

func _draw():
    ## Eye Markings:
    
    # Forming the triangles' points:
    var triangle_left_points: PackedVector2Array
    var triangle_right_points: PackedVector2Array
    
    triangle_left_points = ShapeGens.TriangleFormulator.formulate_triangle_points(triangle_size, triangle_v_offset, -triangle_h_offset, displacement, false, rotation_angle) # First triangle (pointing up)
    triangle_right_points = ShapeGens.TriangleFormulator.formulate_triangle_points(triangle_size, triangle_v_offset, triangle_h_offset, displacement, true, rotation_angle) # Second triangle (pointing down)
    
    # Drawing the triangles:
    draw_polygon(triangle_left_points, [triangle_color1]) # First triangle (pointing up)
    draw_polygon(triangle_right_points, [triangle_color1]) # Second triangle (pointing down)
