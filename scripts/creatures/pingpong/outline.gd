@tool

extends Node2D

const HypocycloidGenerator = preload("res://scripts/autoloads/HypocycloidGenerator.gd")

# --- Customize these parameters ---
@onready var main_body = get_parent().get_child(0)
@onready var num_cusps: int = main_body.num_cusps        # Number of cusps (n). Must be >= 3 for the 'squished' shape.
@onready var outer_radius: float = main_body.outer_radius # Corresponds to R = nr. This is the distance to the cusps.
@onready var outline_width: float = main_body.outline_width
@onready var num_points: int = main_body.num_points     # How many points to generate (more = smoother)
@onready var center_offset: Vector2 = Vector2.ZERO # Offset the shape's center

func _ready() -> void:
    scale = main_body.scale + Vector2(0.15, 0.15)

func _draw():
    
    ## Forming the shapes
    var points_body: PackedVector2Array = HypocycloidGenerator.generate_hypocycloid_points(num_cusps, outer_radius, num_points, center_offset) # Main Body
    
    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polygon(points_body, [Color.BLACK])
