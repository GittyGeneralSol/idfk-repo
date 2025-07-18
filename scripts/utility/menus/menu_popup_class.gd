extends Node2D

class_name MenuPopup

# --- Appearance Parameters --
@export var menu_width: float = 600
@export var menu_length: float = 300
@export var displacement: Vector2 = Vector2.ZERO
@export var outline_menu_length: float = 10.0
@export var col: Color = Color.DIM_GRAY

# --- Internal State ---
var _current_scale_tween: Tween = null # Variable to hold the active tween

func _ready() -> void:
    queue_redraw()
    do_popup_anim()
    
func do_popup_anim():
    scale = Vector2.ZERO
    empower_scale()

func _draw() -> void:
    # Draw Main menu:
    construct_n_draw_rect(Color.BLACK, menu_width, menu_length, displacement, outline_menu_length) # Outline
    construct_n_draw_rect(col, menu_width, menu_length, displacement, 0.0) # Body

# Helper function to draw a rectangle centered around a displacement point
func construct_n_draw_rect(color: Color, rect_menu_width: float, rect_menu_length: float, displ: Vector2 = Vector2.ZERO, outline_w: float = 0.0):
    var size = Vector2(rect_menu_width + outline_w, rect_menu_length + outline_w)
    var top_left = displ - size / 2.0
    var target_rect = Rect2(top_left, size)

    draw_rect(target_rect, color)
    
# --- Tweening Functions ---
func tween_scale_to(target_scale: Vector2, time: float, ease_type: Tween.EaseType):
    # Kill any existing tween managed by this script
    if _current_scale_tween and _current_scale_tween.is_valid():
        _current_scale_tween.kill()

    _current_scale_tween = create_tween()
    _current_scale_tween.set_ease(ease_type).set_trans(Tween.TRANS_ELASTIC)

    _current_scale_tween.tween_property(self, "scale", target_scale, time)
    
    await _current_scale_tween.finished

# --- Control Functions ---
func collapse_scale():
    if scale > Vector2.ZERO:
        await tween_scale_to(Vector2.ZERO, 0.5, Tween.EASE_IN)

func empower_scale():
    if scale < Vector2.ONE:
        tween_scale_to(Vector2.ONE, 0.5, Tween.EASE_OUT)
