extends Node2D

# --- Appearance Parameters --
@export var max_size_variation: Vector2 = Vector2(10, 10)
@export var target_rect_height: float = 20
@export var target_rect_width: float = 20
@export var curr_rect_height: float = 20
@export var curr_rect_width: float = 20
@export var outline_width: float = 0.0
@export var rect_col: Color = Color.CHARTREUSE

## Displ:
@export var target_displ: Vector2 = Vector2.ZERO
@export var curr_displ: Vector2 = Vector2.ZERO:
    set(new_value):
        queue_redraw() # Redraw upon set.
        curr_displ = new_value
    get:
        return curr_displ

# --- Internal State ---
var _current_rect_tween: Tween = null # Variable to hold the active tween

func _ready() -> void:
    queue_redraw()
    empower_rect()
    
    if Engine.is_editor_hint():
        return # Do not delete in editor
    
    var time = randf_range(3.0, 5.0)
    delayed_deletion(time)

func delayed_deletion(time_till_deletion: float):
    await get_tree().create_timer(time_till_deletion).timeout
    queue_free()

func _draw() -> void:
    # Draw the rect:
    construct_n_draw_rect(Color.BLACK, curr_rect_width, curr_rect_height, curr_displ, outline_width) # Outline
    construct_n_draw_rect(rect_col, curr_rect_width, curr_rect_height, curr_displ, 0.0) # Filling
    
    # Helper function to draw a rectangle centered around a displacement point
func construct_n_draw_rect(color: Color, rect_bar_height: float, rect_bar_width: float, displ: Vector2 = Vector2.ZERO, outline_w: float = 0.0):
    var size = Vector2(rect_bar_height + outline_w, rect_bar_width + outline_w)
    var top_left = displ - size / 2.0
    var target_rect = Rect2(top_left, size)

    draw_rect(target_rect, color)
    
# --- Tweening Functions ---
func tween_rect_to(target_displ: Vector2, target_width: float, target_height: float, time: float, ease_type: Tween.EaseType = Tween.EASE_IN):
    # Kill any existing tween managed by this script
    if _current_rect_tween and _current_rect_tween.is_valid():
        _current_rect_tween.kill()

    _current_rect_tween = create_tween()
    _current_rect_tween.set_ease(ease_type).set_trans(Tween.TRANS_QUAD)

    _current_rect_tween.tween_property(self, "curr_displ", target_displ, time)
    _current_rect_tween.parallel().tween_property(self, "curr_rect_width", target_height, time)
    _current_rect_tween.parallel().tween_property(self, "curr_rect_height", target_width, time)
    
    await _current_rect_tween.finished

# --- Control Functions ---
func empower_rect():
    var time = randf_range(0.2, 0.7)
    await tween_rect_to(target_displ, target_rect_width, target_rect_height, time, Tween.EASE_OUT)
