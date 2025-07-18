extends Node

const SFX_PLAYER = preload("res://scenes/utility/worldly_sfx_player.tscn")

# Sounds will not exceed or go below these volumes:
@export var max_loudness_db: float = 24.0
@export var min_loudness_db: float = -12.0

func play_one_shot_2d(caller: Object, sound_stream: AudioStream, initial_loudness_db: float, max_diff_in_pitch: float = 0.2, additional_pitch: float = 0.0):
    if not sound_stream or not caller:
        printerr("SoundManager: Tried to play a null audio stream, or caller is invalid.")
        return
        
    if "dead" in caller:
        if caller.dead:
            return # Do not play sound if a creature is dead

    var sfx_player = SFX_PLAYER.instantiate()
    sfx_player.stream = sound_stream
    sfx_player.pitch_scale = randf_range(1.0 - max_diff_in_pitch/2, 1.0 + max_diff_in_pitch/2) # Sounds better
    sfx_player.pitch_scale += additional_pitch
    
    # Positioning:
    sfx_player.parent = caller
    
    var calculated_volume_db = initial_loudness_db - pow(1.0 / Vars.camera_zoom, 2)
    sfx_player.volume_db = clampf(calculated_volume_db, min_loudness_db, max_loudness_db)
    
    var caller_world = WorldUtils.get_parent_world(caller)
    caller_world.add_child(sfx_player)
    
    # Positioning again
    sfx_player._worldly_position = caller._worldly_position

    sfx_player.finished.connect(Callable(sfx_player, "queue_free"))
    
    sfx_player.play()
