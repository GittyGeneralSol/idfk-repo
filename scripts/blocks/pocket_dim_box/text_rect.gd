@tool

extends Node2D

@export var initial_displacement_y: float = 5
@onready var rich_text_label: RichTextLabel = $RichTextLabel
@export var text_color: String = "black"
@export var text: String = "Osamayjzg"

func _ready() -> void:
    rich_text_label.scale = Vector2(0.1, 0.1)
    rich_text_label.text = "[font_size=120][b][color=" + text_color + "]" + text + "[/color][/b][/font_size]"
    queue_redraw()

func update_text(new_text: String):
    text = new_text
    rich_text_label.text = "[font_size=120][b][color=" + text_color + "]" + text + "[/color][/b][/font_size]"
    
func _draw() -> void:
    var displacement = Vector2(Constants.tile_size / 2, Constants.tile_size / 2) * 1 / scale
    var x_size = Constants.half_block_extent * 1.4
    var y_size = 20
    var pos = Vector2(Constants.half_block_extent - x_size/2, initial_displacement_y - y_size/2)
    pos -= displacement
    var name_rect: Rect2 = Rect2(pos, Vector2(x_size, y_size))
    
    draw_rect(name_rect, Color.BISQUE)
