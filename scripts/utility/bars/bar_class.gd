extends Node2D

class_name Bar

# --- Appearance Parameters --
@export var bar_height: float = 20
@export var bar_width: float = 200
@export var filling_percent: float = 100
@export var displacement: Vector2 = Vector2.ZERO
@export var outline_bar_width: float = 10.0
@export var empty_color: Color = Color.DIM_GRAY
@export var filling_col: Color = Color.CHARTREUSE

# --- Internal State ---
var _current_scale_tween: Tween = null # Variable to hold the active tween
var _recently_updated: bool = false # Flag to disturb deletion loop

func _ready() -> void:
    if not get_tree():
        return
    
    queue_redraw()
    await do_popup_anim() # Wait until the bar does animation
    
    if Engine.is_editor_hint():
        return # Do not delete in editor
    
    delayed_deletion_attempt_loop(2.0)
    
func do_popup_anim():
    scale = Vector2.ZERO
    await empower_scale()
    
func delayed_deletion_attempt_loop(time_till_attempt: float = 3.0):
    if not get_tree():
        return
    
    await get_tree().create_timer(time_till_attempt).timeout
    
    if _recently_updated:
        _recently_updated = false # reset flag
        delayed_deletion_attempt_loop(time_till_attempt) ## Restart attempt
    else:
         attempt_delete()
    
func attempt_delete():
    await collapse_scale() ## Wait until bar's scale goes to zero
    queue_free()

func _draw() -> void:
    var filling_width = calculate_fw()
    var filling_displ = Vector2(displacement.x - ( bar_width - filling_width) / 2, displacement.y)
    
    # Draw Main bar:
    construct_n_draw_rect(Color.BLACK, bar_width, bar_height, displacement, outline_bar_width) # Outline
    construct_n_draw_rect(empty_color, bar_width, bar_height, displacement, 0.0) # Background
    construct_n_draw_rect(filling_col, filling_width, bar_height, filling_displ, 0.0) # Filling

func calculate_fw() -> float:
    var fw = bar_width * ( filling_percent / 100 )
    return fw

# Helper function to draw a rectangle centered around a displacement point
func construct_n_draw_rect(color: Color, rect_bar_height: float, rect_bar_width: float, displ: Vector2 = Vector2.ZERO, outline_w: float = 0.0):
    var size = Vector2(rect_bar_height + outline_w, rect_bar_width + outline_w)
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
        await tween_scale_to(Vector2.ONE, 0.1, Tween.EASE_OUT)

func update_percent(percent: float):
    _recently_updated = true # Set flag to true
    percent = clampf(percent, 0.0, 100.0)
    filling_percent = percent
    queue_redraw()
    
