@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_points: int = 4
@export var circumrad: float = Constants.std_cr
@export var outline_width: float = 10.0
@export var shape_color: Color = Color.ALICE_BLUE
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
    var outer_points = PolygonGenerator.generate_polygon_points(num_points, circumrad, displacement, rotation_deg, true)
    var hbe = Constants.half_block_extent
    var w = hbe - width
    var inner_circumrad = w * sqrt(2)
    var inner_points = PolygonGenerator.generate_polygon_points(num_points, inner_circumrad, displacement, rotation_deg, true)
    var points = organize_points_for_shape(outer_points, inner_points)
    
    # Drawing the body
    if points.size() > 2: # draw_polygon needs at least 3 points
        # draw_polyline(points_outline, Color.BLACK, outline_width) # Drawn by independent node
        draw_polygon(points, [shape_color])
    else: push_error("draw_polygon() needs at least three points.")
    
func organize_points_for_shape(outer_points: PackedVector2Array, inner_points: PackedVector2Array) -> PackedVector2Array:
    var correct_o_points: PackedVector2Array
    correct_o_points.append(outer_points[1])
    correct_o_points.append(outer_points[0])
    correct_o_points.append(outer_points[3])
    correct_o_points.append(outer_points[2])
    
    var correct_i_points: PackedVector2Array
    correct_i_points.append(inner_points[2])
    correct_i_points.append(inner_points[3])
    correct_i_points.append(inner_points[0])
    correct_i_points.append(inner_points[1])
    correct_i_points.append(inner_points[2])
    
    var correct_points = correct_o_points + correct_i_points
    correct_points.append(outer_points[2])
    
    return correct_points
