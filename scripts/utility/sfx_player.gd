extends AudioStreamPlayer2D

class_name WorldlySFXPlayer

@export var parent: Node # Keeps changing position to keep up with parent

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    # Setter function for 'worldly_position'
    set(new_value):
        _worldly_position = new_value
        WorldUtils.set_worldly_position(self, new_value)

    # Getter function for 'worldly_position'
    get:
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position
        
func _process(_delta: float) -> void:
    if Engine.is_editor_hint() or not parent or not WorldUtils.get_parent_world(self):
        return # Play sounds only when appropriate parents exist, and also do not play in editor.
        
    _worldly_position = parent._worldly_position
