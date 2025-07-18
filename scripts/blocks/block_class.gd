extends Node

class_name Block

@export var block_type: String = "unspecified"
@export var special_data_title: String = "special_data"
@export var stored_data: Dictionary # Set this according to block (Data stored by block)
@export var _setting_up_vars: bool = false

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

func update_block():
    pass

func b_setup_variables(b_type: String, b_worldly_pos: Vector2 = _worldly_position, b_spcl_dat_title: String = special_data_title):
    if Engine.is_editor_hint():
        return
    
    _setting_up_vars = true # Set flag to not trigger bs
    block_type = b_type
    special_data_title = b_spcl_dat_title
    add_to_group(block_type + "s")
    _worldly_position = b_worldly_pos
    _setting_up_vars = false # Unset flag
    
func get_special_data(requested_data: String = "stored_data"):
    match(requested_data):
        "title": return special_data_title
        "stored_data": return stored_data
        _: return {}; print("BlockClass - Was requested nonsensical data.")
