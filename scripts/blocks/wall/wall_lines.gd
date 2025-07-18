extends Node2D

const PolygonGenerator = preload("res://scripts/shape_generators/PolygonGenerator.gd")

@export var tile_size: float = Constants.tile_size
@export var wall_line_col: Color = Color.CADET_BLUE
@export var wall_corner_col: Color = Color.CADET_BLUE
@export var wall_corner_ext_col: Color = Color.CADET_BLUE
@export var width: float = 30
@export var distance_from_bounds: float = 0
@export var is_frozen: bool ## Set by parent
@onready var self_pos: Vector2
@export var current_tile_map: Dictionary

func _ready() -> void:
    WorldUtils.world_created.connect(Callable(self, "on_parent_world_official_creation"))
    queue_redraw()
    
func on_parent_world_official_creation(world_name: String, world_node: World, caller: Node):
    queue_redraw() # When the world's creation is officially announced, do a full redraw.

func _draw() -> void:
    draw_wall_lines_master()
    draw_wall_lines_master(width, distance_from_bounds + 35, wall_line_col, wall_corner_col, wall_corner_ext_col)

func draw_wall_lines_master(width: float = width, distance_from_bounds: float = distance_from_bounds, line_col: Color = wall_line_col, corner_col: Color = wall_corner_col, corner_ext_col: Color = wall_corner_ext_col):
    ## Update tile_map:
    self_pos = round(WorldUtils.get_parent_block(self)._worldly_position / Constants.tile_size)
    current_tile_map = WorldUtils.get_parent_world_tile_map(self)
    
    ## Horiz and Vertical sides:
    if !check_pos(Vector2.DOWN) or is_frozen: draw_wall_line(Vector2i.DOWN, width, line_col, distance_from_bounds)
    if !check_pos(Vector2.UP) or is_frozen: draw_wall_line(Vector2i.UP, width, line_col, distance_from_bounds)
    if !check_pos(Vector2.RIGHT) or is_frozen: draw_wall_line(Vector2i.RIGHT, width, line_col, distance_from_bounds)
    if !check_pos(Vector2.LEFT) or is_frozen: draw_wall_line(Vector2i.LEFT, width, line_col, distance_from_bounds)
    
    ## Diagonals:
    if !check_pos(Vector2(1, 1)) or !check_pos(Vector2.DOWN) or !check_pos(Vector2.RIGHT) or is_frozen: draw_wall_line(Vector2i(1, 1), width, corner_col, distance_from_bounds)
    if !check_pos(Vector2(1, -1)) or !check_pos(Vector2.UP) or !check_pos(Vector2.RIGHT) or is_frozen: draw_wall_line(Vector2i(1, -1), width, corner_col, distance_from_bounds)
    if !check_pos(Vector2(-1, 1)) or !check_pos(Vector2.DOWN) or !check_pos(Vector2.LEFT) or is_frozen: draw_wall_line(Vector2i(-1, 1), width, corner_col, distance_from_bounds)  
    if !check_pos(Vector2(-1, -1)) or !check_pos(Vector2.UP) or !check_pos(Vector2.LEFT) or is_frozen: draw_wall_line(Vector2i(-1, -1), width, corner_col, distance_from_bounds)
    
    ## Corner extensions:
    if check_pos(Vector2.UP) and !is_frozen: draw_corner_extensions(Vector2.UP, distance_from_bounds, width, corner_ext_col)
    if check_pos(Vector2.DOWN) and !is_frozen: draw_corner_extensions(Vector2.DOWN, distance_from_bounds, width, corner_ext_col)
    if check_pos(Vector2.LEFT) and !is_frozen: draw_corner_extensions(Vector2.LEFT, distance_from_bounds, width, corner_ext_col)
    if check_pos(Vector2.RIGHT) and !is_frozen: draw_corner_extensions(Vector2.RIGHT, distance_from_bounds, width, corner_ext_col)     

func check_pos(dir: Vector2) -> bool:
    var check_pos: Vector2 = self_pos + dir
    if current_tile_map.has(check_pos):
        if not current_tile_map[check_pos]:
            return false
        
        if current_tile_map[check_pos] is Wall:
            return true
        else: return false
    else:
        return false

func draw_wall_line(dir: Vector2i,  w: float, color: Color = wall_line_col, d: float = distance_from_bounds):
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

func draw_corner_extensions(dir: Vector2, d: float = distance_from_bounds, w: float = width, color: Color = wall_corner_col):
    var x_size = 0.0
    var y_size = 0.0
    var x_pos = tile_size / 2 - w / 2 - d
    var y_pos = tile_size / 2 - w / 2 - d
    var center_of_corner: Vector2
     
    if dir == Vector2.UP:
        x_size = w
        y_size = d
           
        ## RIGHT EXTENSION
        center_of_corner = Vector2(x_pos, -y_pos)
        center_of_corner.y -= w / 2 + d / 2
        
        var final_pos: Vector2 = center_of_corner + Vector2(-x_size/2, -y_size/2)
        var corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
        ## LEFT EXTENSION
        center_of_corner = Vector2(-x_pos, -y_pos)
        center_of_corner.y -= w / 2 + d / 2
        
        final_pos = center_of_corner + Vector2(-x_size/2, -y_size/2)
        corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
    
    if dir == Vector2.DOWN:
        x_size = w
        y_size = d
        
        ## RIGHT EXTENSION
        center_of_corner = Vector2(x_pos, y_pos)
        center_of_corner.y += w / 2 + d / 2
        
        var final_pos: Vector2 = center_of_corner + Vector2(-x_size/2, -y_size/2)
        var corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
        ## LEFT EXTENSION
        center_of_corner = Vector2(-x_pos, y_pos)
        center_of_corner.y += w / 2 + d / 2
        
        final_pos = center_of_corner + Vector2(-x_size/2, -y_size/2)
        corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
    if dir == Vector2.LEFT:
        x_size = d
        y_size = w
        
        ## TOP EXTENSION
        center_of_corner = Vector2(-x_pos, -y_pos)
        center_of_corner.x -= w / 2 + d / 2
        
        var final_pos: Vector2 = center_of_corner + Vector2(-x_size/2, -y_size/2)
        var corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
        ## BOTTOM EXTENSION
        center_of_corner = Vector2(-x_pos, y_pos)
        center_of_corner.x -= w / 2 + d / 2
        
        final_pos = center_of_corner + Vector2(-x_size/2, -y_size/2)
        corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
    if dir == Vector2.RIGHT:
        x_size = d
        y_size = w
        
        ## TOP EXTENSION
        center_of_corner = Vector2(x_pos, -y_pos)
        center_of_corner.x += w / 2 + d / 2
        
        var final_pos: Vector2 = center_of_corner + Vector2(-x_size/2, -y_size/2)
        var corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
        
        ## BOTTOM EXTENSION
        center_of_corner = Vector2(x_pos, y_pos)
        center_of_corner.x += w / 2 + d / 2
        
        final_pos = center_of_corner + Vector2(-x_size/2, -y_size/2)
        corner_ext_rect = Rect2(final_pos, Vector2(x_size, y_size))
        draw_rect(corner_ext_rect, color)
