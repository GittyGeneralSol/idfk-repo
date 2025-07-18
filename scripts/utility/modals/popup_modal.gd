@tool

extends MenuPopup

class_name Modal

@onready var modal_title_label: RichTextLabel = $ModalTitle
@onready var input_box: LineEdit = $InputBox
@onready var cancel_button: PolygonButton = $CancelButton
@onready var submit_button: PolygonButton = $SubmitButton

# --- Modal ---
@export var modal_title: String = "Name the Dimension"
@export var text_color: String = "gold"
@export var modal_title_label_size: Vector2 = Vector2(300, 75)
@export var modal_title_label_scale: Vector2 = Vector2(0.2, 0.2)
@export var modal_title_label_displ: Vector2 = Vector2(0, -100)
@export_subgroup("Input Box")
@export var placeholder: String = "Dimension Name.."
@export var input_box_size: Vector2 = Vector2(500, 75)
@export var input_box_scale: Vector2 = Vector2(0.2, 0.2)
@export var input_box_max_ch: int = 10

# -- Internal State --
var _input_box_text: String

# -- Signals ---
@export var connect_modal_to_node: Node = null
# Emit the _input_box_text for context.
signal modal_submitted(_input_box_text)
signal modal_canceled(_input_box_text)

func _ready() -> void:
    super._ready()
    setup_modal()
    setup_input_box()
    setup_buttons()
    queue_redraw()
    
func _process(_delta: float) -> void:
    _input_box_text = input_box.text
    
func setup_modal():
    # --- Connect this modal's signals to another node if specified ---
    if connect_modal_to_node and is_instance_valid(connect_modal_to_node): # Check if node is valid
        if connect_modal_to_node.has_method("on_modal_submission"): connect("modal_submitted", Callable(connect_modal_to_node, "on_modal_submission"))
        else: print("MODAL %s: target_node lacks 'on_modal_submission' method." % _input_box_text)
        if connect_modal_to_node.has_method("on_modal_cancellation"): connect("modal_canceled", Callable(connect_modal_to_node, "on_modal_cancellation"))
        else: print("MODAL %s: target_node lacks 'on_modal_cancellation' method." % _input_box_text)
    # else: # Handle no target node or connecting elsewhere
    
    var viewport_size = get_viewport().size
    self.position = Vector2(viewport_size.x / 2.0, viewport_size.y / 2.0)
    modal_title_label.scale = Vector2(0.2, 0.2)
    modal_title_label.set_deferred("size", modal_title_label_size / modal_title_label_scale)
    modal_title_label.position = -Vector2(modal_title_label_size.x/2, modal_title_label_size.y/2) + modal_title_label_displ
    modal_title_label.text =  "[font_size=125][b][color=" + text_color + "]" + modal_title + "[/color][/b][/font_size]"
    
func setup_input_box():
    input_box.scale = Vector2(0.2, 0.2)
    input_box.set_deferred("size", input_box_size / input_box_scale)
    input_box.set_deferred("max_length", input_box_max_ch)
    input_box.position = -Vector2(input_box_size.x/2, input_box_size.y/2)
    input_box.placeholder_text = placeholder

func setup_buttons():
    submit_button.def_button_color = Color.CHARTREUSE
    submit_button.switch_button_color = Color.CHARTREUSE

func on_button_down(action_string: String):
    pass
    
func on_button_release(action_string: String):
    print("MODAL - button released: ", action_string)
    
    ## CANCELED
    if action_string == "modal_close": 
        modal_canceled.emit(_input_box_text)
        await collapse_scale()
        queue_free()
    
    ## SUBMIT TEXT, THEN QUEUE FREE
    elif action_string == "modal_submit": 
        modal_submitted.emit(_input_box_text)
        await collapse_scale()
        queue_free()

func on_button_press_cancellation(action_string: String):
    pass
