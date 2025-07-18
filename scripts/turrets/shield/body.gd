@tool

extends Node2D

const HypocycloidGenerator = preload("res://scripts/shape_generators/HypocycloidGenerator.gd")
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_lobes: int = 3        # Number of cusps (n). Must be >= 3 for the 'squished' shape.
@export var circumrad: float = 90 # Corresponds to R = nr. This is the distance to the cusps.
@export var outline_width: float = 10.0
@export var shape_color: Color = Color.SILVER # Example color (pink)
@export var center_offset: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = 90 # Rotate the body

@export var points_body: PackedVector2Array # Accessed by deco

func _draw():
    
    ## Forming the shapes
    var points_body: PackedVector2Array = PolygonGenerator.generate_reuleaux_polygon_points(num_lobes, circumrad, center_offset, rotation_deg)
    var points_outline: PackedVector2Array = PolygonGenerator.generate_reuleaux_polygon_points(num_lobes, circumrad + outline_width, center_offset, rotation_deg) # Outline
    
    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polygon(points_outline, [Color.BLACK])
        draw_polygon(points_body, [shape_color])
    else: push_error("draw_polygon() needs at least three points.")
