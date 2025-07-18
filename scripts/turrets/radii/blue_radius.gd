@tool
extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Onready Nodes ---
# Requires an Area2D child named "RadiusArea2D"
# Requires a CollisionShape2D child of RadiusArea2D named "CollisionShape2D"
# The CollisionShape2D needs a CircleShape2D resource assigned in the Inspector
@onready var radius_area_2d: Area2D = $RadiusArea2D
@onready var collision_shape_2d: CollisionShape2D = $RadiusArea2D/CollisionShape2D
@onready var collision_circle_shape: CircleShape2D # Initialized in _ready

# --- Appearance ---
@export_category("Appearance")
@export var num_points: int = 8
@export var max_circumrad: float = 1000
@export var outline_width: float = 20
@export var shape_color: Color = Color(Color.AQUA, 0.1)
@export var displacement: Vector2 = Vector2.ZERO # Offset center relative to node position
@export var rotation_deg: float = 0

@export var outline_correction: float = -10.0001 # Adjust outline size relative to body

# --- Behavior ---
@export_category("Behavior")
@export var turret_on: bool = true

# --- Internal State ---
var curr_circumrad: float = 0.0
var _current_radius_tween: Tween = null # Variable to hold the active tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Validate required nodes and resource
    
    collision_circle_shape = collision_shape_2d.shape as CircleShape2D # Store the shape resource

    # Initialize radius and trigger initial tween
    curr_circumrad = 0.0
    if turret_on:
        empower_radius()

    # Set initial collision shape radius
    collision_circle_shape.radius = curr_circumrad


# Called every frame.
func _process(_delta: float) -> void:
    # Update collision shape radius to match current drawing radius
    if is_instance_valid(collision_circle_shape) and !is_equal_approx(curr_circumrad, max_circumrad):
        collision_circle_shape.radius = curr_circumrad
        queue_redraw()


# Called by Godot to draw custom visuals.
func _draw():
    if curr_circumrad > 0.0:
        # Generate points for drawing (offset by displacement)
        var points_body = PolygonGenerator.generate_polygon_points(num_points, curr_circumrad, displacement, rotation_deg)
        var points_outline = PolygonGenerator.generate_polygon_points(num_points, curr_circumrad + outline_width + outline_correction, displacement, rotation_deg)

        # Close the outline polyline
        if points_outline.size() > 0:
             points_outline.append(points_outline[0])

        # Drawing the body and outline
        if points_body.size() > 2:
            if points_outline.size() > 1:
                 draw_polyline(points_outline, Color(shape_color, shape_color.a / 2), outline_width)
            draw_polygon(points_body, [shape_color])


# --- Tweening Functions ---
func tween_radius_to(target_rad: float, time: float):
    # Kill any existing tween managed by this script
    if _current_radius_tween and _current_radius_tween.is_valid():
        _current_radius_tween.kill()

    _current_radius_tween = create_tween()
    _current_radius_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

    _current_radius_tween.tween_property(self, "curr_circumrad", target_rad, time)


# --- Control Functions ---
func collapse_radius():
    if curr_circumrad > 0.0:
        tween_radius_to(0.0, 1.5)


func empower_radius():
    if curr_circumrad < max_circumrad:
        tween_radius_to(max_circumrad, 3.0)


# --- Toggle Function ---
func toggle_radius(on: bool):
    turret_on = on
    if turret_on:
        empower_radius()
    else:
        collapse_radius()
