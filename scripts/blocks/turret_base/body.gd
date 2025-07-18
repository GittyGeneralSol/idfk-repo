@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = Constants.std_cr
@export var outline_width: float = 10.0
@export var shape_color: Color = Color.WHITE_SMOKE
@export var displacement: Vector2 = Vector2.ZERO
@export var rotation_deg: float = -45.0
@export var width: float = 24

@export var outline_correction: float = -2.5001

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ## Trigger the first draw:
    queue_redraw()   
    
func _draw():
    ## Forming the shapes
    var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad, displacement, rotation_deg, true) # Main Body
    
    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polygon(points_body, [shape_color])
    else: push_error("draw_polygon() needs at least three points.")
