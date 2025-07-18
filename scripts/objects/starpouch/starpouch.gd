extends Node2D

@export var pulsing: bool = true
@onready var stop_pulsing: Timer = $stop_pulsing

func _ready() -> void:
    if pulsing: pulse()

func pulse():
    var tween_scale = create_tween()
    
    # Animate from current scale to 1.15x scale over a period of 0.75 seconds:
    tween_scale.tween_property(self, "scale", Vector2(1.15, 1.15), 0.75)
    # Animate from current scale to 0.85x scale over a period of 0.75 seconds:
    tween_scale.tween_property(self, "scale", Vector2(0.85, 0.85), 0.75)
    
    await tween_scale.finished
    tween_scale.stop()
    
    if pulsing:
        pulse() ## For looping
    else:
        var tween_scale_return = create_tween() ## Create a new tween
        
        # Animate from current scale to 1.0x scale over a period of 0.75 seconds:
        tween_scale_return.tween_property(self, "scale", Vector2(1.0, 1.0), 0.75)
        await tween_scale_return.finished

func _on_stop_pulsing_timeout() -> void:
    pulsing = false
