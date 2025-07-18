@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 6 # Or number of sides of polygon
@export var circumrad: float = 100
@export var shape_color: Color = Color.SLATE_GRAY
@export var displacement: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = -45 # Rotate the body
@export var num_of_rings: int = 4

func _draw():
    ## Forming the shapes
    
    for ring_number in num_of_rings:
        var subtract_color: Color = Color(0.025, 0.025, 0.025, 0) * ring_number
        var subtract_cirrad: float = 35 * ring_number
        var col = shape_color - subtract_color
        var n = num_points if ring_number % 2 == 0 else 4
    
        var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(n, circumrad - subtract_cirrad, displacement, rotation_deg) # Main Body
    
        # Drawing the body
        if points_body.size() > 2: # draw_polygon needs at least 3 points
            draw_polygon(points_body, [col])
        
