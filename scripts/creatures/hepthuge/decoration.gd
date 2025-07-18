@tool
extends BaseCreatureDeco # Assuming this is the base class from Script 

func _ready():
    _generate_deco()

func _generate_deco():
    # Start with a fresh list of shapes to build.
    var new_shapes = []
    
    var n = await get_property_by_path("PROP-/body/params/num_points")
    var radius = await get_property_by_path("PROP-/body/params/radius")
    var apothem = radius * cos(PI/n)
    
    var angle_slice = ( TAU / n )
    for line_number in n:
        var rot = angle_slice * line_number - angle_slice/2
        var pos = Vector2.RIGHT.rotated(rot) * (apothem - 20)
        var points_of_line = []
        var shape_rotation = rad_to_deg(angle_slice * line_number + angle_slice) + 90
        
        new_shapes.append({
            "shape_type": CustomShapeLogic.SHAPE_TYPE.LINE,
            "color": Color.RED,
            "length": 220.0,
            "width": 13.0,
            "rotation": shape_rotation,
            "position": pos
        })
    
    self.shape_stack = new_shapes
