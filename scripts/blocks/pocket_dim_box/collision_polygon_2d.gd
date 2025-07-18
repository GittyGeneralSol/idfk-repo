@tool

extends CollisionPolygon2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

# --- Taken from body ---
@onready var main_body = get_parent().get_child(0)
@onready var num_points: int = main_body.num_points # Or number of sides of polygon
@onready var circumrad: float = main_body.circumrad # So that each side of a square is precisely 200 pixels long
@onready var displacement: Vector2 = main_body.displacement # Offset the shape's center
@onready var rotation_deg: float = main_body.rotation_deg # Rotate the body

func _ready() -> void:
    var points_body: PackedVector2Array = PolygonGenerator.generate_polygon_points(num_points, circumrad, displacement, rotation_deg) # Main Body Points
    polygon = points_body
