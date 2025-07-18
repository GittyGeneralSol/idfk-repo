@tool

extends BaseCreaturePart
class_name BaseCreatureEyelids

# --- Internal State - Set by the Parent Eye ---
var lid_behavior: String = "twolid"
var eyelid_color_top: Color = Color.SKY_BLUE
var eyelid_color_bottom: Color = Color.SKY_BLUE

# The data needed for drawing, cached from the logic object.
var _logic_params: Dictionary
var _bounds := Rect2()
var _points := PackedVector2Array()
var _magnitude := 0.0
var _visual_center := Vector2.ZERO

# --- Control Openness ---
@export_range(0.0, 1.0, 0.01) var openness: float = 1.0:
    set(value):
        var clamped_value = clamp(value, 0.0, 1.0)
        if not is_equal_approx(clamped_value, openness):
            openness = clamped_value # Assign the clamped value to the variable
            queue_redraw() # Request a redraw of this node
            
# --- Configuration - Called by the Parent ---
func configure(logic_object: CustomShapeLogic):
    if not is_instance_valid(logic_object):
        # Clear data if the logic object is invalid
        _points.clear()
        _bounds = Rect2()
        return

    # Cache all the necessary drawing data from the logic object ONCE.
    _logic_params = logic_object.params
    _points = logic_object.get_points()
    _bounds = logic_object.get_bounding_box()
    _visual_center = logic_object.get_visual_center()
    _magnitude = logic_object.get_shape_magnitude()
    #rotation_degrees = logic_object.params.get("rotation")
    
    queue_redraw()

# --- The main drawing function ---
func _draw():
    if openness >= 1.0 - 0.001: return

    # --- Fully Closed State ---
    if openness <= 0.001:
        if lid_behavior == "omni" and not _points.is_empty():
            draw_polygon(_points, [eyelid_color_top])
        else:
            draw_rect(_bounds, eyelid_color_top, true)
        return

    # --- Partially Open State ---
    match lid_behavior:
        "twolid":
            var total_height = _bounds.size.y
            var covered_per_lid = (total_height * (1.0 - openness)) / 2.0
            if covered_per_lid < 0.1: return

            var top_rect = Rect2(_bounds.position, Vector2(_bounds.size.x, covered_per_lid))
            var bottom_rect = Rect2(_bounds.position.x, _bounds.end.y - covered_per_lid, _bounds.size.x, covered_per_lid)
            
            draw_rect(top_rect, eyelid_color_top, true)
            draw_rect(bottom_rect, eyelid_color_bottom, true)

        "unilid":
            var total_height = _bounds.size.y
            var covered_height = total_height * (1.0 - openness)
            if covered_height < 0.1: return

            var lid_rect = Rect2(_bounds.position, Vector2(_bounds.size.x, covered_height))
            draw_rect(lid_rect, eyelid_color_top, true)

        "omni":
            var points_to_draw = _points.duplicate()
            if points_to_draw.is_empty():
                points_to_draw = _get_points_from_bounds(_bounds)
            if points_to_draw.is_empty(): return
                
            points_to_draw.append(points_to_draw[0])

            var max_width = _magnitude
            var visual_openness = sqrt(openness)
            var current_width = (1.0 - visual_openness) * max_width

            if current_width > 0.5:
                draw_polyline(points_to_draw, eyelid_color_top, current_width)

        "circle":
            var center = _visual_center
            var size = max(_bounds.size.x, _bounds.size.y)
            
            var radius = size / sqrt(2)
            var max_width = size * sqrt(2)

            var current_width = (1.0 - openness) * max_width

            if current_width > 0.5:
                # Setting 'filled' to false and passing a width creates the outline.
                draw_circle(center, radius, eyelid_color_top, false, current_width)
                
        "rectangle":
            # All calculations are self-contained.
            var center = _visual_center
            var size = max(_bounds.size.x, _bounds.size.y)
            var max_width = size * sqrt(2)
            var current_width = (1.0 - openness) * max_width
            
            var rect_size = Vector2.ONE * size
            var rect = Rect2(center - rect_size / 2.0, rect_size)
            
            if current_width > 0.5:
                draw_rect(rect, eyelid_color_top, false, current_width)

        "triangle":
            # All calculations are self-contained.
            var center = _visual_center
            var size = max(_bounds.size.x, _bounds.size.y)
            var max_width = size * sqrt(2)
            var current_width = (1.0 - openness) * max_width

            var radius = size / 2.0
            var points = PackedVector2Array()
            
            for i in 3:
                var angle = (i * TAU / 3.0) - PI / 2.0
                points.append(center + Vector2.RIGHT.rotated(angle) * radius)
            
            points.append(points[0])
            
            if current_width > 0.5:
                draw_polyline(points, eyelid_color_top, current_width)

# Helper to generate points from a Rect2 for the omni fallback
func _get_points_from_bounds(rect: Rect2) -> PackedVector2Array:
    var p = PackedVector2Array()
    p.append(rect.position)
    p.append(Vector2(rect.end.x, rect.position.y))
    p.append(rect.end)
    p.append(Vector2(rect.position.x, rect.end.y))
    return p
