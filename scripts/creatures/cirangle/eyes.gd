@tool
extends BaseCreatureEyeContainer

@export var lid_type: BaseCreatureEye.LID_TYPE = BaseCreatureEye.LID_TYPE.TWOLID
@export var eye_offset: Vector2 = Vector2(50, 0)
@export var eye_radius: float = 25.0

func _ready() -> void:
    generate_eyes()

func generate_eyes():
    clear_created_eyes()

    # Create the Left Eye
    create_eye({
        "lid_type": lid_type,
        "radius": eye_radius,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.ORANGE,
        "eyelid_color_bottom": Color.ORANGE,
        "part_position": -eye_offset # Typically, negative X is left
    })

    # Create the Right Eye
    create_eye({
        "eye_type": CustomShapeLogic.SHAPE_TYPE.MIX,
        "stack": [
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.CIRCLE,
                "angle": 360.0,
                "radius": 25.0,
                "rotation": 0,
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.TRIANGLE,
                "gen_type": ShapeGens.TriangleGenerator.GenerationType.ISOSCELES,
                "size": Vector2(12.5, 25),
                "position": Vector2(-25, 0),
                "rotation": -90,
            },
            {
                "shape_type": CustomShapeLogic.SHAPE_TYPE.TRIANGLE,
                "gen_type": ShapeGens.TriangleGenerator.GenerationType.ISOSCELES,
                "size": Vector2(12.5, 25),
                "position": Vector2(25, 0),
                "rotation": 90,
            }
        ],
        "lid_type": lid_type,
        "radius": eye_radius,
        "eye_color": Color.WHITE,
        "eyelid_color_top": Color.ORANGE,
        "eyelid_color_bottom": Color.ORANGE,
        "part_position": eye_offset # Typically, positive X is right
    })
    
    var eye: BaseCreatureEye = created_eyes[1]
    print(eye.eye_type)
