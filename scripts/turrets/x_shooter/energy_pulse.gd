@tool

extends Node2D

const HypocycloidGenerator = preload("res://scripts/shape_generators/HypocycloidGenerator.gd")
const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Customize these parameters ---
@export var num_lobes: int = 4        # Number of cusps (n). Must be >= 3 for the 'squished' shape.
@export var circumrad: float = 90 # Corresponds to R = nr. This is the distance to the cusps.
@export var outline_width: float = 10.0
@export var shape_color: Color = Color.YELLOW # Example color (pink)
@export var center_offset: Vector2 = Vector2.ZERO # Offset the shape's center
@export var rotation_deg: float = 90 # Rotate the body

@export var points_body: PackedVector2Array # Accessed by deco

## Turret:
@export var turret_on: bool = true

func _ready() -> void:
    if turret_on: tween_scale_to_max()

func _draw():
    ## Forming the shapes
    var points_body: PackedVector2Array = PolygonGenerator.generate_reuleaux_polygon_points(num_lobes, circumrad, center_offset, rotation_deg)
    points_body.append(points_body[0])

    # Drawing the body
    if points_body.size() > 2: # draw_polygon needs at least 3 points
        draw_polyline(points_body, shape_color, outline_width)
    else: push_error("draw_polygon() needs at least three points.")
    
func tween_scale_to_max():
    scale = Vector2(0.05, 0.05) ## Reset scale
    
    # Create tweens
    var tween_scale = create_tween()
    
    # Animate from current rad (0.05) to '1.5' over a period of 2 seconds:
    tween_scale.tween_property(self, "scale", Vector2(1.5, 1.5), 2)
    
    await tween_scale.finished
    tween_scale.kill()
    
    if turret_on:
        tween_scale_to_max() ## For looping

func set_color(new_color: Color):
    shape_color = new_color
    queue_redraw()
