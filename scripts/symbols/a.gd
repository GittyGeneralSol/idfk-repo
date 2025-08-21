@tool
extends Polygon2D

const SymbolShapeGenerator = preload("res://scripts/shape_generators/SymbolShapeGenerator.gd")

func _ready() -> void:
    polygon = SymbolShapeGenerator.get_points("test_shape")
