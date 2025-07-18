@tool
extends BaseCreatureEyeContainer

@export var lid_type: BaseCreatureEye.LID_TYPE = BaseCreatureEye.LID_TYPE.TWOLID
@export var eye_offset: Vector2 = Vector2(50, 0)
@export var eye_radius: float = 25.0
@export var shape_pos: Vector2 = Vector2.ONE:
    set(v): shape_pos = v; generate_eyes()

func _ready() -> void:
    handle_connections()
    generate_eyes()

func generate_eyes():
    clear_created_eyes()
    
    var base_hemi_eye: Dictionary = {
        "eye_type": BaseCreatureEye.TYPE.MIX,
        "boolean_operation": CustomShapeLogic.BooleanOperation.SUBTRACTION,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "angle": 180.0,
                "radius": 85
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.RECTANGLE,
                "position": Vector2(0, -40),
                "size": Vector2(200, 100),
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "angle": 180.0,
                "radius": 45
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "position": shape_pos,
                "radius": 15
            }
        ],
        "shape_scale": Vector2(0.8, 0.8),
        "lid_type": BaseCreatureEye.LID_TYPE.UNILID,
        "draw_outline": true,
        "outline_width": 5.0,
        "outline_color": Color.GREEN_YELLOW,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.GREEN.lightened(0.5),
        "eyelid_color_bottom": Color.GREEN.lightened(0.5),
        "shape_rotation": -180,
        "part_rotation": 180
    }
    
    var top_hemi_eye = base_hemi_eye.duplicate()
    top_hemi_eye["part_rotation"] = 0

    # Create the Top Eye
    create_eye(top_hemi_eye)

    # Create the Bottom Eye
    create_eye(base_hemi_eye)
