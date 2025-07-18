@tool
extends BaseCreatureDeco # Assuming this is the base class from Script 2

@export_group("Base Shape")
@export var num_points: int = 5:
    set(v): num_points = v; _generate_deco()
@export var circumradius: float = 100.0:
    set(v): circumradius = v; _generate_deco()
@export var base_rotation_deg: float = 0.0:
    set(v): base_rotation_deg = v; _generate_deco()

@export_group("Inner Polygon")
@export var inner_poly_color: Color = Color("B05DFF"):
    set(v): inner_poly_color = v; _generate_deco()
@export var inner_poly_outline_width: float = 15.0:
    set(v): inner_poly_outline_width = v; _generate_deco()

@export_group("Vertex Triangles")
@export var triangle_size: float = 20.0:
    set(v): triangle_size = v; _generate_deco()
@export var triangle_color: Color = Color("B05DFF"):
    set(v): triangle_color = v; _generate_deco()
@export var triangle_outline_width: float = 5.0:
    set(v): triangle_outline_width = v; _generate_deco()


func _ready():
    _generate_deco()

# This is the single "brain" function for this object.
# Its only job is to build an array of dictionaries describing the shapes.
func _generate_deco():
    if not is_node_ready():
        call_deferred("_generate_deco")
        return

    # Start with a fresh list of shapes to build.
    var new_shapes = []
    
    # --- 1. Generate the Inner Polygon ---
    # The circumradius of the inner polygon is the apothem of the outer one.
    var angle_slice = (360.0 / num_points) / 2.0
    var apothem = circumradius * cos(deg_to_rad(angle_slice))

    var inner_poly_params: Dictionary = {
        "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
        "num_points": num_points,
        "radius": apothem - inner_poly_outline_width/sqrt(2),
        "position": Vector2.ZERO, # Position is handled by the parent node
        "rotation": base_rotation_deg + 36,
        "color": inner_poly_color,
        "filled": false,
        "width": inner_poly_outline_width
    }
    new_shapes.append(inner_poly_params)

    
    # --- # 2. Generate the Vertex Triangles ---
    # First, find the positions of the vertices on the outer polygon.
    var outer_vertex_positions = PolygonGenerator.generate_polygon_points(
        num_points, 
        apothem, 
        Vector2.ZERO, # Position is relative to this node
        base_rotation_deg
    )

    # Now, create a triangle shape at each of those positions.
    for i in range(outer_vertex_positions.size()):
        var vertex_pos = outer_vertex_positions[i]
        
        # Calculate the rotation to make the triangle "point outwards".
        var angle_of_rotation = (360.0 / num_points) * i + base_rotation_deg + 180.0
        
        var triangle_params: Dictionary = {
            "shape_type": CustomShapeLogic.SHAPE_TYPE.POLYGON,
            "num_points": 3,
            "radius": triangle_size, # The 'radius' of the triangle
            "position": vertex_pos,
            "rotation": angle_of_rotation,
            "color": triangle_color,
            "filled": false,
            "width": triangle_outline_width
        }
        new_shapes.append(triangle_params)


    # --- 3. Final Assignment ---
    # Assign the completed array to the shape_stack.
    # The base class will handle the rest.
    self.shape_stack = new_shapes
