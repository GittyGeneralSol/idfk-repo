extends Node

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

const tile_size: float = 200.0 # How big a tile or block should be
const half_block_extent: float = tile_size / 2
var st_tile_body_points: PackedVector2Array = PolygonGenerator.generate_polygon_points(4, std_cr, Vector2.ZERO, -45.0, true)
var st_tile_outline_points: PackedVector2Array = PolygonGenerator.generate_polygon_points(4, std_cr, Vector2.ZERO, -45.0, true)

## Z-Orders ( All Relative to Parent Worlds ):
const block_z_order: int = 1000
const selector_z_order: int = block_z_order + 1

# If the circumradius of a square is this value,
# then each of its sides will be precisely 200 pixels long.
const std_cr: float = tile_size * sqrt(2) / 2 ## Standard Circumradius. 

func _ready() -> void:
    print("\nCONSTANTS AUTOLOAD - st_tile_body_points: ", st_tile_body_points, "\n")
