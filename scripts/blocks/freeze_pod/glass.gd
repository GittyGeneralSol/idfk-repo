@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 4 # Or number of sides of polygon
@export var circumrad: float = Constants.std_cr + 1.0 - 24
@export var shape_color: Color = Color(Color.ALICE_BLUE - Color(0.75, 0.0, 0.0, 0.7))
@export var displacement: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = -45 # Rotate the body

func _draw():
    ## Forming the shapes
    
    var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad, displacement, rotation_deg) # Main Body
    
    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polygon(points_body, [shape_color])
        
