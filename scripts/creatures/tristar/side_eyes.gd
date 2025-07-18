@tool
extends BaseCreatureEyeContainer

@onready var main_eye: Node2D = $"../main_eye"

# All the parameters needed for the eyes are exposed here.
@export_group("Ring Configuration")
@export var ring_radius: float = 50.0

@export_group("Eye Shape (Star)")
@export var star_outer_rad: float = 15.0
@export var star_inner_rad: float = 7.0
@export var star_num_points: int = 4

@export_group("Eye Appearance")
@export var eye_color: Color = Color.WHITE
@export var eyelid_color: Color = Color.AQUA

func _ready() -> void:
    generate_ring_of_stars()

# Replaces the old _draw() and manual creation.
func generate_ring_of_stars():
    # Clear any previously generated eyes.
    clear_created_eyes()

    # Prepare the dictionary of parameters that will be the same for ALL eyes.
    var eye_template_params = {
        "eye_type": BaseCreatureEye.TYPE.STAR,
        "num_points": star_num_points,
        "outer_radius": star_outer_rad,
        "inner_radius": star_inner_rad,
        "eye_color": eye_color,
        "spinning": true,
        "blink_type": BaseCreatureEye.BLINK_TYPE.SCALING,
        "eyelid_color_top": eyelid_color,
        "eyelid_color_bottom": eyelid_color,
        "has_eyelids": true,
        "lid_type": BaseCreatureEye.LID_TYPE.OMNI,
        "initial_openness": master_openness
    }
    
    # Call the powerful ring creation function from the base class.
    
    cluster_params = {
        "num_eyes": 5,
        "rotational_anchor": "PART-/eye_system/main_eye",
        "rotational_anchor_offset": ( 90 / 5 ),
        "ring_radius": ring_radius,
        "eye_params": eye_template_params,
        "blink_delay": 0.05
    }
    
    await get_tree().process_frame
    print("Obj: ", rotational_anchor)
