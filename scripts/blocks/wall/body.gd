@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = Constants.std_cr
@export var outline_width: float = 10.0
@export var shape_color: Color = Color(Color.POWDER_BLUE + Color(0.1, 0.1, 0.1, 0.0))
@export var displacement: Vector2 = Vector2.ZERO
@export var rotation_deg: float = -45.0

@export var outline_correction: float = -2.5001

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ## Trigger the first draw:
    queue_redraw()   
    
func _draw():
    ## Forming the shapes
    var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad, displacement, rotation_deg, true) # Main Body
    var points_outline: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad + outline_width + 0 + outline_correction, displacement, rotation_deg, true) # Outline
    
    # Adding an extra point to outline array to form a closed shape:
    var extra_point = points_outline[0] # First point from array
    points_outline.append(extra_point)
    
    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        # draw_polyline(points_outline, Color.BLACK, outline_width) # Drawn by independent node
        draw_polygon(points_body, [shape_color])
    else: push_error("draw_polygon() needs at least three points.")
