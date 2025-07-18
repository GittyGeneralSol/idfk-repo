@tool
extends BaseCreaturePart

var params: Dictionary:
    set(v):
        # This is the line we are testing
        update_from_params(v)

func _init(new_params: Dictionary = {}):
    print("INIT CALLED")
    params = new_params
    print("INIT FINISHED")

func _ready():
    print("READY CALLED - j")

# We need a dummy function for the test to run without errors
func update_from_params(p):
    print("UPDATE CALLED")
    var live_params = await get_live_values_of_dict(params)
