@tool

extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    # Setter function for 'worldly_position'
    set(new_value):
        _worldly_position = new_value
        var parent_world = WorldUtils.get_parent_world(self)
        WorldUtils.set_worldly_position(self, new_value)

    # Getter function for 'worldly_position'
    get:
        var parent_world = WorldUtils.get_parent_world(self) 
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

@export var tile_size: float = Constants.tile_size
@export var outer_col: Color = Color.LIGHT_GOLDENROD
@export var inner_col = Color(Color.LIGHT_GOLDENROD - Color(0.2, 0.2, 0.2, 0.0))
@export var outer_width: float = 15
@export var inner_width: float = 5
@export var distance_from_bounds_inner: float = 10
@onready var self_pos: Vector2

func _ready() -> void:
    self_pos = round(WorldUtils.get_parent_block(self)._worldly_position / Constants.tile_size)
    queue_redraw()

func _draw() -> void:
    draw_wall_lines_master(outer_width, 0, outer_col, outer_col, outer_col)
    draw_wall_lines_master(inner_width, distance_from_bounds_inner, inner_col, inner_col, inner_col)
    draw_wall_lines_master(inner_width, distance_from_bounds_inner + inner_width, Color.BLACK, Color.BLACK, Color.BLACK)
    
func draw_wall_lines_master(width: float, distance_from_bounds: float, line_col: Color, corner_col: Color, corner_ext_col: Color):
    
    ## Horiz and Vertical sides:
    draw_wall_line(Vector2i.DOWN, width, line_col, distance_from_bounds)
    draw_wall_line(Vector2i.UP, width, line_col, distance_from_bounds)
    draw_wall_line(Vector2i.RIGHT, width, line_col, distance_from_bounds)
    draw_wall_line(Vector2i.LEFT, width, line_col, distance_from_bounds)
    
    ## Diagonals:
    draw_wall_line(Vector2i(1, 1), width, corner_col, distance_from_bounds)
    draw_wall_line(Vector2i(1, -1), width, corner_col, distance_from_bounds)
    draw_wall_line(Vector2i(-1, 1), width, corner_col, distance_from_bounds)  
    draw_wall_line(Vector2i(-1, -1), width, corner_col, distance_from_bounds)
    
      

func draw_wall_line(dir: Vector2i,  w: float, color: Color, d: float):
    var x: float
    var y: float
    x = tile_size / 2 - w / 2 - d # Position for corner, will get replaced if not a corner
    y = tile_size / 2 - w / 2 - d # Position for corner, will get replaced if not a corner
    
    var line_points: PackedVector2Array
    var corner_square_points: PackedVector2Array
    var corner_circumrad: float = w / 2 * sqrt(2)
    
    match(dir):
        Vector2i.DOWN:
            x = tile_size / 2 - w - d # Because increasing width causes shitting over the outline
            y = tile_size / 2 - w / 2 - d # Because increasing width causes shitting over the outline
            line_points = [Vector2(x, y), Vector2(-x, y)]
        Vector2i.UP:
            x = tile_size / 2 - w - d # Because increasing width causes shitting over the outline
            y = tile_size / 2 - w / 2 - d # Because increasing width causes shitting over the outline
            line_points = [Vector2(x, -y), Vector2(-x, -y)]
        Vector2i.RIGHT:
            x = tile_size / 2 - w / 2 - d # Because increasing width causes shitting over the outline
            y = tile_size / 2 - w - d # Because increasing width causes shitting over the outline
            line_points = [Vector2(x, y), Vector2(x, -y)]
        Vector2i.LEFT:
            x = tile_size / 2 - w / 2 - d # Because increasing width causes shitting over the outline
            y = tile_size / 2 - w - d # Because increasing width causes shitting over the outline
            line_points = [Vector2(-x, y), Vector2(-x, -y)]
        Vector2i(1, 1):
            corner_square_points = PolygonGenerator.generate_polygon_points(4, corner_circumrad, Vector2(x, y), -45, true)
        Vector2i(1, -1):
            corner_square_points = PolygonGenerator.generate_polygon_points(4, corner_circumrad, Vector2(x, -y), -45, true)
        Vector2i(-1, 1):
            corner_square_points = PolygonGenerator.generate_polygon_points(4, corner_circumrad, Vector2(-x, y), -45, true)
        Vector2i(-1, -1):
            corner_square_points = PolygonGenerator.generate_polygon_points(4, corner_circumrad, Vector2(-x, -y), -45, true)
            
    if line_points.size() > 1:    
        draw_polyline(line_points, color, w)
    if corner_square_points.size() > 2:
        draw_polygon(corner_square_points, [color])
