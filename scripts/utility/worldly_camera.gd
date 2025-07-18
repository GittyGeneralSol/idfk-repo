extends Camera2D

class_name WorldlyCamera

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
