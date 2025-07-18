@tool
extends Polygon2D
@onready var shapes: ShapeLogicRenderer = $Shapes
@onready var circular_arc: Node2D = $"Circular Arc"
@onready var a: Polygon2D = $A

@export var backup_data: PackedVector2Array

func _ready() -> void:
    backup_data = polygon
    transform_polygon(Transform2D(0.0, Vector2(0, 0)))
    
    #polygon = shapes._resultant_shape_points
    #polygon = a.polygon
    #SaveManager._form_and_save_symbol(polygon, "cylinder_pointy", "A cylinder with a spike on top.")
    print_polygon()
    
func print_polygon(poly: PackedVector2Array = polygon):
    var string: String = "Polygon: ["
    
    for i in range(poly.size()):
        var point = poly[i]
        string += "Vector2"
        string += str(point)
        if (i + 1) != poly.size():
            string += ", "
    
    string += "]"
    print(string)
    
func merge_polygons(points_stack: Array[PackedVector2Array]) -> PackedVector2Array:
    var result_polygon: PackedVector2Array
    if points_stack.size() < 2:
        return points_stack[0] if points_stack.size() == 1 else []
    
    result_polygon = points_stack[0]
    for i in range(1, points_stack.size()):
        var points_i = points_stack[i]
        var result_polygons = Geometry2D.merge_polygons(result_polygon, points_i)
        if result_polygons.size() > 1:
            printerr("Multiple polygonal result.")
            return []
        result_polygon = result_polygons[0]
    
    return result_polygon
    
func transform_polygon(transform_matrix: Transform2D = Transform2D()):
    var points = polygon
    points *= transform_matrix
    polygon = points
