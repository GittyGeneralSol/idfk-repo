@tool
extends BaseCreatureEyeContainer

@export_group("Eye Positions")
@export var main_eye_offset: Vector2 = Vector2(25, 0)
@export var side_eye_offset: Vector2 = Vector2(45, 25)

@export_group("Eye Radii")
@export var main_eye_radius: float = 20.0
@export var side_eye_radius: float = 15.0

@export_group("Eyelid Colors")
@export var main_eyelid_color: Color = Color.DARK_SLATE_BLUE
@export var side_eyelid_color: Color = Color.DARK_SLATE_BLUE

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

    # --- Side Eyes ---
    create_eye({
        "radius": side_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": side_eyelid_color,
        "eyelid_color_bottom": side_eyelid_color,
        "part_position": Vector2(-side_eye_offset.x, -side_eye_offset.y),
    })
    
    create_eye({
        "radius": side_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": side_eyelid_color,
        "eyelid_color_bottom": side_eyelid_color,
        "part_position": Vector2(-side_eye_offset.x, side_eye_offset.y),
    })
    
    create_eye({
        "radius": side_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": side_eyelid_color,
        "eyelid_color_bottom": side_eyelid_color,
        "part_position": Vector2(side_eye_offset.x, -side_eye_offset.y),
    })
    
    create_eye({
        "radius": side_eye_radius,
        "eye_color": eye_pupil_color,
        "eyelid_color_top": side_eyelid_color,
        "eyelid_color_bottom": side_eyelid_color,
        "part_position": side_eye_offset,
    })
