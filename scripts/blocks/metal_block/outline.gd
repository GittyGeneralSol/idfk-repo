@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Taken from body ---
@onready var main_body = get_parent().get_child(0)
@onready var num_points: int = main_body.num_points # Or number of sides of polygon
@onready var circumrad: float = main_body.circumrad # So that each side of a square is precisely 200 pixels long
@onready var outline_width: float = main_body.outline_width
@onready var displacement: Vector2 = main_body.displacement # Offset the shape's center
@onready var rotation_deg: float = main_body.rotation_deg # Rotate the body

@onready var outline_correction: float = -2.5001 # How much to reduce the circumrad by

func _ready() -> void:
    ## Trigger the first draw:
    queue_redraw()
    
func _draw():
    ## Forming the shapes
    var points_outline = PolygonGenerator.generate_polygon_points(num_points, circumrad + outline_width + 0 + outline_correction, displacement, rotation_deg) # Outline
    
    # Adding an extra point to outline array to form a closed shape:
    var extra_point = points_outline[0] # First point from array
    points_outline.append(extra_point)
    
    # Drawing the body
    draw_polyline(points_outline, Color.BLACK, outline_width)
