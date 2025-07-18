@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 4 # Or number of sides of polygon
@export var circumrad: float = Constants.std_cr - 10
@export var shape_color: Color = Color(Color.POWDER_BLUE - Color(0.1, 0.1, 0.1, 0.0))
@export var displacement: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = -45 # Rotate the body
@export var num_of_rings: int = 3
@export var width: float = 10.0

func _draw():
    ## Forming the shapes
    
    for ring_number in num_of_rings:
        var subtract_cr = 35 * ring_number
        var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad - subtract_cr, displacement, rotation_deg, true) # Main Body
    
        # Adding an extra point to outline array to form a closed shape:
        var extra_point = points_body[0] # First point from array
        points_body.append(extra_point)
    
        # Drawing the body
        if points_body.size() > 2: # draw_polygon needs at least 3 points
            draw_polyline(points_body, shape_color, width)
        
