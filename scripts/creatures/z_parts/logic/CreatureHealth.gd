extends RefCounted
class_name CreatureHealth

signal died
signal health_updated(current_hp, max_hp, original_hp)
signal health_updated_by_setter(current_hp, max_hp)
signal took_damage(amount)

var _current_hp: float
var _max_hp: float
var _is_dead: bool = false

# The constructor takes the initial values it needs.
func _init(initial_hp: float, initial_max_hp: float):
    set_hp(initial_hp, initial_max_hp)
    
func set_hp(hp: float = _current_hp, max_hp: float = _max_hp):
    _max_hp = max_hp
    _current_hp = clamp(hp, 0, _max_hp)
    emit_signal("health_updated_by_setter", _current_hp, _max_hp)

func take_damage(amount: float):
    if _is_dead:
        return
        
    var _original_hp = _current_hp
    _current_hp = clamp(_current_hp - amount, 0, _max_hp)
    emit_signal("health_updated", _current_hp, _max_hp, _original_hp)
    emit_signal("took_damage", amount)

    if _current_hp <= 0:
        _is_dead = true
        emit_signal("died")

func get_hp() -> float:
    return _current_hp
    
func get_max_hp() -> float:
    return _max_hp

func is_dead() -> bool:
    return _is_dead
