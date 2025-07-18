extends Node2D

class_name GunOne

const X_BULLET = preload("res://scenes/turrets/bullets/x_bullet.tscn")
const GUN_LOAD = preload("res://assets/Creatures/sfx/gun-load-pixabay.mp3")
const GUNSHOT = preload("res://assets/Creatures/sfx/gunshot_1_pixabay.mp3")

@onready var fire_rate_timer: Timer = $FireRateTimer

## Positioning:
var _worldly_position: Vector2 = Vector2.ZERO:
    # Setter function for 'worldly_position'
    set(new_value):
        _worldly_position = new_value
        var parent_world = WorldUtils.get_parent_world(self)
        WorldUtils.set_worldly_position(self, new_value)

    # Getter function for 'worldly_position'
    get:
        var parent_world = WorldUtils.get_parent_world(self) 
        _worldly_position = WorldUtils.get_worldly_position(self)
        return _worldly_position

# --- Appearance Parameters --
@export_category("Gun Appearance")
@export var barrel_width: float = 20.0
@export var barrel_length: float = 140.0
@export var displacement: Vector2 = Vector2(0, -20)
@export var outline_barrel_length: float = 10.0
@export var col: Color = Color.SILVER

# --- Behavior Parameters ---
@export_category("Gun Behavior")
@export var turret_on: bool = true
@export var recoil_distance: float = 20.0
@export var max_range: float = 2000.0
@export var fire_rate: float = 0.5
@export var cock_time: float = 0.25
@export var recoil_time: float = 0.1
@export var cock_hold_time: float = 0.2
@export var rotation_speed: float = 120.0 # Degrees per second for aiming
@export var bullet_speed: float = 1000.0 # Pixels per second for bullets
@export var aim_tolerance_degrees: float = 1.0
@export_subgroup("Enemies")
@export var enemy_groups: PackedStringArray = ["enemy", "tristar", "tricipher"] # Default to "enemies" group

# --- Internal State ---
var _parent_world: Node
var _parent_block: Node
var _allow_turning: bool = false
var _recoil_tween: Tween = null
var _current_target_enemy: BaseCreature = null # Store the current target
var _is_pointing_towards_enemy: bool = false
var _is_shooting: bool = false # New flag to indicate if gun is firing rn or not

func _ready() -> void:
    _parent_world = WorldUtils.get_parent_world(self)
    _parent_block = WorldUtils.get_parent_block(self)
    queue_redraw()
    
    ## Timer:
    fire_rate_timer.wait_time = fire_rate

    if turret_on: turn_on_gun()

func get_enemy_list() -> Array:
    var enemy_list: Array = []
    
    if enemy_groups.is_empty():
        return []
    
    for group_name in enemy_groups:
        var nodes_in_group = get_tree().get_nodes_in_group(group_name)
        enemy_list += nodes_in_group
    return enemy_list

# --- _process for continuous aiming and firing logic ---
func _process(delta: float) -> void:
    if turret_on and _allow_turning:
        _current_target_enemy = find_nearest_enemy(get_enemy_list())
        
        if _current_target_enemy != null:
            var desired_angle_rad = _worldly_position.direction_to(_current_target_enemy._worldly_position).angle()
            desired_angle_rad += PI / 2.0 # Adjust for gun pointing upwards at 0 degrees rotation.
            
            var desired_angle_degrees = rad_to_deg(desired_angle_rad)
            var current_rotation_degrees = get_parent().rotation_degrees

            var angle_diff = wrapf(desired_angle_degrees - current_rotation_degrees, -180.0, 180.0)

            if abs(angle_diff) <= aim_tolerance_degrees:
                get_parent().rotation_degrees = desired_angle_degrees
                _is_pointing_towards_enemy = true
            else:
                var max_rotation_delta = rotation_speed * delta
                var rotation_amount = clampf(angle_diff, -max_rotation_delta, max_rotation_delta)
                get_parent().rotation_degrees += rotation_amount
                _is_pointing_towards_enemy = false

            # Firing Logic:
            if _is_pointing_towards_enemy and fire_rate_timer.is_stopped():
                _is_shooting = true
                fire_bullet()
                fire_rate_timer.start()
            
            ## Debug prints
            # print("GUN: Desired Angle (raw deg): ", desired_angle_degrees)
            # print("GUN: Current Rotation (raw deg): ", get_parent().rotation_degrees)
            # print("GUN: Angle Difference (wrapped deg): ", angle_diff)
            # print("GUN: _is_pointing_towards_enemy: ", _is_pointing_towards_enemy)
            
        else:
            _is_pointing_towards_enemy = false
            # If no target, stop continuous firing.
            _is_shooting = false
            fire_rate_timer.stop()
    else:
        # If turret is off or not allowed to turn, stop aiming and firing.
        _is_pointing_towards_enemy = false
        _is_shooting = false
        fire_rate_timer.stop()


func rotate_towards_nearest_enemy():
    _current_target_enemy = find_nearest_enemy(get_enemy_list())
    if _current_target_enemy != null:
        var desired_angle_rad = _worldly_position.direction_to(_current_target_enemy._worldly_position).angle() + PI / 2.0
        rotate_towards(rad_to_deg(desired_angle_rad))
    else:
        print("GUN: No enemy found for immediate rotation.")


func rotate_towards(target_angle_degrees: float):
    get_parent().rotation_degrees = target_angle_degrees
    
func find_nearest_enemy(enemies) -> BaseCreature:
    if enemies.is_empty():
        return null
        
    var fixed_gun_position = _parent_block._worldly_position
    
    var closest_enemy: BaseCreature = null
    var shortest_distance: float = INF

    for enemy in enemies:
        if not is_instance_valid(enemy) or not enemy.is_inside_tree():
            continue
        
        var is_in_same_world = (WorldUtils.get_parent_world(enemy) == _parent_world)
        
        if not enemy is BaseCreature or not is_in_same_world:
            continue
            
        var dist_to_enemy = fixed_gun_position.distance_to(enemy._worldly_position)
        
        ## Do not proceed with this enemy if it's dead or beyond maximum range
        if enemy.dead or dist_to_enemy > max_range:
            continue
            
        ## Do not proceed with this enemy if it is behind a block:
        var enemy_angle_rad = _worldly_position.direction_to(enemy._worldly_position).angle()
        var block_in_way: bool = WorldUtils.is_block_in_way(self, enemy_angle_rad, dist_to_enemy, "rad")
        
        #print("GUN: Is a block in way?: ", block_in_way)
        if block_in_way:
            continue

        if dist_to_enemy < shortest_distance: # is_equal_approx not needed for distance comparison
            shortest_distance = dist_to_enemy
            closest_enemy = enemy
            
    if closest_enemy:
        return closest_enemy
    else:
        return null

func get_distance_to(first_object: Node, node: Node) -> float:
    if not node:
        return 0
        
    var first_object_position = first_object.position
    var distance =  first_object_position.distance_to(node._worldly_position)
    
    return distance

# Called by Godot to draw custom visuals
func _draw() -> void:
    # Draw Main Barrel:
    construct_n_draw_rect(Color.BLACK, barrel_width, barrel_length, displacement, outline_barrel_length) # Outline
    construct_n_draw_rect(col, barrel_width, barrel_length, displacement, 0.0) # Body

    # Draw Muzzle:
    var muzzle_disp = Vector2(displacement.x, displacement.y + barrel_length / 2.0 + (barrel_width + 10) / 2.0)
    construct_n_draw_rect(Color.BLACK, barrel_width + 10, 20, muzzle_disp, outline_barrel_length) # Muzzle Outline
    construct_n_draw_rect(col, barrel_width + 10, 20, muzzle_disp, 0.0) # Muzzle Body


# Helper function to draw a rectangle centered around a displacement point
func construct_n_draw_rect(color: Color, rect_barrel_width: float, rect_barrel_length: float, displ: Vector2 = Vector2.ZERO, outline_w: float = 0.0):
    var size = Vector2(rect_barrel_width + outline_w, rect_barrel_length + outline_w)
    var top_left = displ - size / 2.0
    var target_rect = Rect2(top_left, size)

    draw_rect(target_rect, color)
    
func fire_bullet():
    if not _parent_world or not _parent_block or not _is_shooting:
        return
    
    if _current_target_enemy.get_hp() <= 0.0 or _current_target_enemy.is_dead():
        _current_target_enemy = find_nearest_enemy(get_enemy_list())
        return ## Do not fire at dead enemies
    
    var current_bullet = X_BULLET.instantiate()
    var muzzle_offset_from_gun_origin = Vector2(0, -80) # Bullet's local spawn point
    var bullet_global_spawn_position = _parent_block.position + muzzle_offset_from_gun_origin.rotated(get_parent().rotation)
    
    current_bullet.z_index = -1
    current_bullet._target = _current_target_enemy
    current_bullet.max_travel_distance = max_range
    
    _parent_block.add_child(current_bullet)
    
    WorldUtils.set_worldly_position(current_bullet, bullet_global_spawn_position)

    # Calculate bullet's initial travel direction based on the gun's current rotation.
    # If the gun's 0 rotation points UP (negative Y), then Vector2.UP is its base "forward".
    # We rotate this 'UP' vector by the gun's actual rotation (get_parent().rotation gives radians).
    var bullet_travel_direction = Vector2.UP.rotated(get_parent().rotation)

    # Call a setup method on the bullet to give it its direction and speed.
    current_bullet.setup_bullet(bullet_travel_direction, bullet_speed)

    recoil_anim()
    play_snd(GUNSHOT, 12.0)

# Triggers the recoil animation
func recoil_anim(firing: bool = true, recoil_or_cock_time: float = recoil_time):
    if _recoil_tween and _recoil_tween.is_valid():
        _recoil_tween.kill()
        _recoil_tween = null

    _allow_turning = false # Disable turning during recoil
    _is_shooting = false # Stop firing during recoil

    var recoil_direction_in_parent_space = Vector2(0, 1).rotated(rotation)
    var recoil_offset_local = recoil_direction_in_parent_space * recoil_distance

    var original_local_pos = Vector2.ZERO
    var target_local_pos = original_local_pos + recoil_offset_local

    _recoil_tween = create_tween()
    _recoil_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

    _recoil_tween.tween_property(self, "position", target_local_pos, recoil_or_cock_time)
    if !firing: _recoil_tween.tween_interval(cock_hold_time)
    _recoil_tween.tween_property(self, "position", original_local_pos, recoil_or_cock_time)

    _recoil_tween.connect("finished", Callable(self, "_on_recoil_finished"))


func _on_recoil_finished():
     _recoil_tween = null
     position = Vector2.ZERO
     _allow_turning = true # Re-enable turning after recoil
     _is_shooting = true # Resume shooting after recoil

func play_snd(sound_stream: AudioStream, loudness: float = 3.0):
    if WorldUtils.is_in_player_world(_parent_block): ## Only play sounds if the player is also in this world
        SoundManager.play_one_shot_2d(self, sound_stream, loudness)

func turn_on_gun():
    recoil_anim(false, cock_time)
    play_snd(GUN_LOAD, 5.0)
    await get_tree().create_timer(1.5).timeout
    
    _allow_turning = true
    _is_shooting = true # Start allowing shooting after cocking animation
    # rotate_towards_nearest_enemy() # Snap to initial target

func turn_off_gun():
    _allow_turning = false
    _is_shooting = false
    fire_rate_timer.stop() # Ensure timer is stopped when gun is off

func toggle_gun(on: bool):
    turret_on = on
    if turret_on:   
          turn_on_gun()
    else:
        print("GUN: Turret toggled OFF.")
        turn_off_gun()
