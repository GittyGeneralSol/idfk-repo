extends RefCounted
class_name CustomSerializer

# --- Serialization of Data ---
static func serialize_dictionary(dict: Dictionary) -> Dictionary:
    var formatted_dict: Dictionary
    for property_name in dict.keys():
        var value = dict[property_name]
        value = serialize_variable(value)
        formatted_dict[property_name] = value
    return formatted_dict
    
static func serialize_array(arr: Array) -> Array:
    var formatted_arr: Array
    formatted_arr.resize(arr.size())
    for i in range(arr.size()):
        var value = arr[i]
        value = serialize_variable(value)
        formatted_arr[i] = value
    return formatted_arr
    
static func serialize_color(col: Color) -> String:
    var formatted_col: String
    
    if col.a != 1.0:
        formatted_col = "#" + col.to_html(false)
        return formatted_col
        
    formatted_col = "#" + col.to_html(true)
    return formatted_col
    
static func serialize_variable(value: Variant) -> Variant:
    var formatted_val: Variant
    
    # PERFORM Operations ON DATA BY TYPE
    match(typeof(value)):
        TYPE_DICTIONARY:  formatted_val = serialize_dictionary(value)
        TYPE_INT:         formatted_val = value
        TYPE_FLOAT:       formatted_val = value
        TYPE_VECTOR2:     formatted_val = {"x": value.x, "y": value.y }
        TYPE_VECTOR3:     formatted_val = {"x": value.x, "y": value.y, "z": value.z }
        TYPE_VECTOR4:     formatted_val = {"x": value.x, "y": value.y, "z": value.z, "w": value.w }
        TYPE_COLOR:       formatted_val = serialize_color(value)
        TYPE_STRING:      formatted_val = value
        TYPE_STRING_NAME: formatted_val = value as String
        TYPE_BOOL:        formatted_val = value
        TYPE_ARRAY:       formatted_val = serialize_array(value)
        TYPE_PACKED_VECTOR2_ARRAY: formatted_val = serialize_array(value)
        TYPE_PACKED_STRING_ARRAY:  formatted_val = serialize_array(value)
        _:                formatted_val = var_to_str(value)
        
    return formatted_val
    
# --- Deserialization of Data ---
static func deserialize_variable(value: Variant) -> Variant:
    var deserialized_val: Variant
    
    # PERFORM Operations ON DATA BY TYPE
    match(typeof(value)):
        TYPE_DICTIONARY:  deserialized_val = deserialize_dictionary(value)
        TYPE_INT:         deserialized_val = value
        TYPE_FLOAT:       deserialized_val = value
        TYPE_VECTOR2:     deserialized_val = value
        TYPE_VECTOR3:     deserialized_val = value
        TYPE_VECTOR4:     deserialized_val = value
        TYPE_COLOR:       deserialized_val = value
        TYPE_STRING:      deserialized_val = deserialize_string(value)
        TYPE_STRING_NAME: deserialized_val = deserialize_string(value as String)
        TYPE_BOOL:        deserialized_val = value
        TYPE_ARRAY:       deserialized_val = deserialize_array(value)
        TYPE_PACKED_VECTOR2_ARRAY: deserialized_val = value
        TYPE_PACKED_STRING_ARRAY:  deserialized_val = value
        _:                deserialized_val = str_to_var(value)
        
    return deserialized_val
    
static func deserialize_dictionary(dict: Dictionary) -> Variant: 
    ## Check whether this dict is actually another formatted type..
    
    # Check for Color
    if dict.size() == 4 and dict.has_all(["r", "g", "b", "a"]):
        var r = dict.get("r"); var g = dict.get("g"); var b = dict.get("b"); var a = dict.get("a")
        if (r is float or r is int) and (g is float or g is int) and (b is float or b is int) and (a is float or a is int):
            return Color(r, g, b, a)
    
    # Check for Vector4
    if dict.size() == 4 and dict.has_all(["x", "y", "z", "w"]):
        var x = dict.get("x"); var y = dict.get("y"); var z = dict.get("z"); var w = dict.get("w")
        if (x is float or x is int) and (y is float or y is int) and (z is float or z is int) and (w is float or w is int):
            return Vector4(x, y, z, w)

    # Check for Vector3
    if dict.size() == 3 and dict.has_all(["x", "y", "z"]):
        var x = dict.get("x"); var y = dict.get("y"); var z = dict.get("z")
        if (x is float or x is int) and (y is float or y is int) and (z is float or z is int):
            return Vector3(x, y, z)
            
    # Check for Vector2
    if dict.size() == 2 and dict.has_all(["x", "y"]):
        var x = dict.get("x"); var y = dict.get("y")
        if (x is float or x is int) and (y is float or y is int):
            return Vector2(x, y)
        
    ## Normal deserialization
    var deserialized_dict: Dictionary
    for property_name in dict.keys():
        var value = dict[property_name]
        value = deserialize_variable(value)
        deserialized_dict[property_name] = value
    return deserialized_dict
    
static func deserialize_string(str: String) -> Variant:
    ## Check whether this string is actually another formatted type..
    
    # Check for color
    if Color.html_is_valid(str) and str.begins_with("#"):
        return Color.html(str)
    
    ## Normal deserialization
    return str
    
static func deserialize_array(arr: Array) -> Array:
    var deserialized_arr: Array
    deserialized_arr.resize(arr.size())
    for i in range(arr.size()):
        var value = arr[i]
        value = deserialize_variable(value)
        deserialized_arr[i] = value
    return deserialized_arr
