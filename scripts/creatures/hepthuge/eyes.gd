@tool
extends BaseCreatureEyeContainer

@export_group("Eye Positions")
@export var main_eye_offset: Vector2 = Vector2(100, 0)
@export var hourglass_eye_offset: Vector2 = Vector2(0, 0)

@export_group("Eye Radii")
@export var main_eye_radius: float = 60.0
@export var hourglass_eye_width: float = 100
@export var hourglass_eye_notch_width: float = 5
@export var hourglass_eye_height: float = 150

@export_group("Eyelid Colors")
@export var main_eyelid_color: Color = Color.DARK_RED
@export var hourglass_eye_color: Color = Color.DARK_RED

@export_group("Eye Colors")
@export var eye_pupil_color: Color = Color.WHITE

func _ready() -> void:
    generate_eyes()

func generate_eyes():
    clear_created_eyes()

    # --- Main Eyes ---
    create_eye({
        "radius": main_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": main_eyelid_color,
        "eyelid_color_bottom": main_eyelid_color,
        "part_position": main_eye_offset,
    })
    
    create_eye({
        "radius": main_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": main_eyelid_color,
        "eyelid_color_bottom": main_eyelid_color,
        "part_position": -main_eye_offset,
    })
    
    # --- Hourglass Eye ---
    
    create_eye({
        "eye_type": BaseCreatureEye.TYPE.HOURGLASS,
        "lid_type": BaseCreatureEye.LID_TYPE.TWOLID,
        "width": hourglass_eye_width,
        "height": hourglass_eye_height,
        "notch_width": hourglass_eye_notch_width,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": hourglass_eye_color,
        "eyelid_color_bottom": hourglass_eye_color,
    })
