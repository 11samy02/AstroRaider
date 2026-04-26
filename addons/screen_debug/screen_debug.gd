@tool
@icon("res://addons/screen_debug/icon.svg")


## ScreenDebug is a professional runtime debug overlay for Godot 4.5 that allows developers to inspect node properties, call methods, and visualize real-time values directly on the screen.[br][br] 
## It is designed to help both debugging and learning the Godot engine by showing the effects of property changes instantly. [br][br]
## The plugin supports complex expressions including method calls, array and dictionary access, vector calculations, and chained expressions.[br][br]
## It's particularly useful for character debugging, physics testing, and understanding how nodes interact in your scene.[br]
class_name ScreenDebug extends CanvasLayer


#region EXPORTS
@export_group("Debug", "debug_")
## Enables or disables the debug overlay visibility and process.
@export var debug_active: bool = true:
	set(value):
		debug_active = value
		visible = debug_active


## Optional title displayed at the top of the debug panel.
@export_placeholder("Title") var debug_title: String


## CanvasLayer rendering layer.
@export_range(0, 10, 1, "or_less", "or_greater") var debug_layer: int = 1:
	set(value):
		debug_layer = value
		layer = debug_layer


## Target node whose properties and methods will be inspected.
@export var debug_target: Node


@export_group("Debug/Font", "debug_")
## Font size for both normal and bold text.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_font_size: float = 30.0:
	set(value):
		debug_font_size = value
		if is_instance_valid(_screen_debug):
			_screen_debug.normal_font_size = debug_font_size
			_screen_debug.bold_font_size = debug_font_size


## Vertical spacing between text lines.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_line_spacing: float = 0.0:
	set(value):
		debug_line_spacing = value
		if is_instance_valid(_screen_debug):
			_screen_debug.line_separation = debug_line_spacing


## Outline thickness applied to the font.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_font_outline: float = 0.0:
	set(value):
		debug_font_outline = value
		if is_instance_valid(_screen_debug):
			_screen_debug.outline_size = debug_font_outline


## Default font color.
@export_color_no_alpha() var debug_default_font_color: Color = Color.WHITE:
	set(value):
		debug_default_font_color = value
		if is_instance_valid(_screen_debug):
			_screen_debug.default_font_color = debug_default_font_color


## Font color used for property and method keys.
@export_color_no_alpha() var debug_key_font_color: Color = Color.WHITE:
	set(value):
		debug_key_font_color = value


## Font color used for property and method values.
@export_color_no_alpha() var debug_value_font_color: Color = Color.WHITE:
	set(value):
		debug_value_font_color = value


@export_group("Debug/Background", "debug_")
## Background panel color.
@export_color_no_alpha() var debug_background_color: Color = Color.BLACK:
	set(value):
		debug_background_color = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_color = debug_background_color


## Background panel opacity.
@export_range(0.0, 1.0, 0.0001) var debug_background_opacity: float = 0.3:
	set(value):
		debug_background_opacity = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_opacity = debug_background_opacity


## Background panel size.
@export var debug_background_size: Vector2 = Vector2(500, 500):
	set(value):
		debug_background_size = value
		if is_instance_valid(_screen_debug):
			_screen_debug.set_display_size(debug_background_size)


## Background panel position on screen.
@export var debug_background_position: Vector2 = Vector2(0, 0):
	set(value):
		debug_background_position = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_position = debug_background_position


## Inner padding between background and text.
@export_range(0.0, 1000.0, 0.01, "or_greater") var debug_background_padding: float = 50.0:
	set(value):
		debug_background_padding = value
		if is_instance_valid(_screen_debug):
			_screen_debug.margin = debug_background_padding


@export_group("Debug/Config")
## Number of decimal places for float formatting.
@export_range(0, 4, 1, "prefer_slider") var floats_decimal_places: int = 2

## Number of decimal places for vector component formatting.
@export_range(0, 4, 1, "prefer_slider") var floats_vector_places: int = 2

## Time interval (in seconds) between debug updates.
@export_range(0.05, 2.0, 0.05) var update_interval := 0.2

## List of methods that are blocked from execution for safety.
@export var not_allowed_methods: PackedStringArray = ["queue_free", "add_child", "set_process", "add_to_group", "move_and_slide"]

## [b]Quick reference for writing expressions in the Inspector[/b][br]
## [br]
## Each expression operates on the node assigned in [code]debug_target[/code].[br]
## You can access:[br]
## [br]
## • Node properties: e.g., [code]"position"[/code], [code]"name"[/code], [code]"health"[/code][br][br]
## • Node methods: e.g., [code]"get_parent()"[/code], [code]"get_children()[0]"[/code],  [code]"get_children()[0].name"[/code][br][br]
## • Arrays: index access or properties like [code]size[/code]/[code]length[/code] e.g., [code]"get_children().size", "get_children().length"[/code][br][br]
## • Dictionaries: key access or using [code]get("key")[/code] e.g., [code]dictionary[key], dictionary.get("key")[/code][br][br]
## • Vectors ([code]Vector2[/code]/[code]Vector3[/code]/[code]Vector4[/code]): 
##   components ([code]x[/code], [code]y[/code], [code]z[/code], [code]w[/code]), methods like [code].length()[/code], [code].dot()[/code], [code].cross()[/code], [code].angle_to()[/code]
##  e.g., [code]"global_position.distance_to(Vector3(0,0,0))"[/code][br][br]
## • Transform3D / Basis: access [code]origin[/code], [code]basis[/code], and [code]basis.x/y/z[/code][br][br]
## [br]
## [b]Syntax examples for Inspector input[/b]:[br]
## [br]
## [b]Node Properties:[/b][br]
## [code]"health"[/code][br]
## [code]"position"[/code][br]
## [code]"velocity"[/code][br]
## [br]
## [b]Methods (no arguments):[/b][br]
## [code]"get_parent()"[/code][br]
## [code]"is_visible()"[/code][br]
##[br]
## [b]Methods (with arguments):[/b][br]
## [code]"get_node("Player")"[/code][br]
## [code]"distance_to(Vector3(1,2,3))"[/code][br]
## [code]"dot(Vector3(1,0,0))"[/code][br]
## [br]
## [b]Arrays:[/b][br]
## [code]"children[0]"[/code]             - first child[br]
## [code]"inventory[2]"[/code]            - third item[br]
## [code]"inventory.size"[/code]           - length of the array[br]
##[br]
## [b]Dictionaries:[/b][br]
## [code]"my_dict['key']"[/code][br]
## [code]"my_dict.get("my_key")"[/code][br]
##[br]
## [b]Chained Expressions:[/b][br]
## [code]"get_parent().position"[/code][br]
## [code]"get_node('Enemy').health"[/code][br]
## [code]"children[0].name"[/code][br]
## [code]"get_children()[0].get_node('Weapon').damage"[/code][br]
##[br]
## [b]Vectors:[/b][br]
## [code]"velocity.x"[/code], [code]"velocity.y"[/code], [code]"velocity.z"[/code][br]
## [code]"velocity.length"[/code][br]
## [code]"velocity.normalized"[/code][br]
## [code]"velocity.dot(Vector3:1,0,0)"[/code][br]
## [code]"velocity.cross(Vector3:0,1,0)"[/code][br]
## [code]"velocity.angle_to(Vector3:0,0,1)"[/code][br]
##[br]
## [b]Transform3D / Basis:[/b][br]
## [code]"transform.origin"[/code][br]
## [code]"transform.basis"[/code][br]
## [code]"transform.basis.x"[/code], [code]"transform.basis.y"[/code], [code]"transform.basis.z"[/code][br]
##[br]
## [b]Important Notes:[/b][br]
## • Unsafe methods such as [code]"queue_free"[/code], [code]"add_child"[/code], [code]"set_process"[/code], [code]"move_and_slide"[/code] are blocked.[br]
## [br]
## • Use [code]quick_expressions[/code] for short, common expressions.[br]
## • Use [code]expressions[/code] array for long or complex expressions, as it provides a larger editor in the Inspector.[br]
@export var quick_expressions: Dictionary[String, String]

## [b]Quick reference for writing expressions in the Inspector[/b][br]
## [br]
## Each expression operates on the node assigned in [code]debug_target[/code].[br]
## You can access:[br]
## [br]
## • Node properties: e.g., [code]"position"[/code], [code]"name"[/code], [code]"health"[/code][br][br]
## • Node methods: e.g., [code]"get_parent()"[/code], [code]"get_children()[0]"[/code],  [code]"get_children()[0].name"[/code][br][br]
## • Arrays: index access or properties like [code]size[/code]/[code]length[/code] e.g., [code]"get_children().size", "get_children().length"[/code][br][br]
## • Dictionaries: key access or using [code]get("key")[/code] e.g., [code]dictionary[key], dictionary.get("key")[/code][br][br]
## • Vectors ([code]Vector2[/code]/[code]Vector3[/code]/[code]Vector4[/code]): 
##   components ([code]x[/code], [code]y[/code], [code]z[/code], [code]w[/code]), methods like [code].length()[/code], [code].dot()[/code], [code].cross()[/code], [code].angle_to()[/code]
##  e.g., [code]"global_position.distance_to(Vector3(0,0,0))"[/code][br][br]
## • Transform3D / Basis: access [code]origin[/code], [code]basis[/code], and [code]basis.x/y/z[/code][br][br]
## [br]
## [b]Syntax examples for Inspector input[/b]:[br]
## [br]
## [b]Node Properties:[/b][br]
## [code]"health"[/code][br]
## [code]"position"[/code][br]
## [code]"velocity"[/code][br]
## [br]
## [b]Methods (no arguments):[/b][br]
## [code]"get_parent()"[/code][br]
## [code]"is_visible()"[/code][br]
##[br]
## [b]Methods (with arguments):[/b][br]
## [code]"get_node("Player")"[/code][br]
## [code]"distance_to(Vector3(1,2,3))"[/code][br]
## [code]"dot(Vector3(1,0,0))"[/code][br]
## [br]
## [b]Arrays:[/b][br]
## [code]"children[0]"[/code]             - first child[br]
## [code]"inventory[2]"[/code]            - third item[br]
## [code]"inventory.size"[/code]           - length of the array[br]
##[br]
## [b]Dictionaries:[/b][br]
## [code]"my_dict['key']"[/code][br]
## [code]"my_dict.get("my_key")"[/code][br]
##[br]
## [b]Chained Expressions:[/b][br]
## [code]"get_parent().position"[/code][br]
## [code]"get_node('Enemy').health"[/code][br]
## [code]"children[0].name"[/code][br]
## [code]"get_children()[0].get_node('Weapon').damage"[/code][br]
##[br]
## [b]Vectors:[/b][br]
## [code]"velocity.x"[/code], [code]"velocity.y"[/code], [code]"velocity.z"[/code][br]
## [code]"velocity.length"[/code][br]
## [code]"velocity.normalized"[/code][br]
## [code]"velocity.dot(Vector3:1,0,0)"[/code][br]
## [code]"velocity.cross(Vector3:0,1,0)"[/code][br]
## [code]"velocity.angle_to(Vector3:0,0,1)"[/code][br]
##[br]
## [b]Transform3D / Basis:[/b][br]
## [code]"transform.origin"[/code][br]
## [code]"transform.basis"[/code][br]
## [code]"transform.basis.x"[/code], [code]"transform.basis.y"[/code], [code]"transform.basis.z"[/code][br]
##[br]
## [b]Important Notes:[/b][br]
## • Unsafe methods such as [code]"queue_free"[/code], [code]"add_child"[/code], [code]"set_process"[/code], [code]"move_and_slide"[/code] are blocked.[br]
## [br]
## • Use [code]quick_expressions[/code] for short, common expressions.[br]
## • Use [code]expressions[/code] array for long or complex expressions, as it provides a larger editor in the Inspector.[br]
@export var expressions: Array[ScreenDebugExpression]:
	set(value):
		expressions = value
		if not is_node_ready(): return
		for expr in expressions:
			if expr:
				expr._init_owner(self)

#endregion


#region PRIVATE PROPERTIES
var _screen_debug_packed_scene: PackedScene = preload("res://addons/screen_debug/scenes/screen_debug_packed_scene.tscn")
var _screen_debug: Panel
var _accum := 0.0
var _warned: bool = false
#endregion


#region ENGINE METHODS
func _ready() -> void:
	_screen_debug = _screen_debug_packed_scene.duplicate(true).instantiate()

	_screen_debug.normal_font_size = debug_font_size
	_screen_debug.bold_font_size = debug_font_size
	_screen_debug.line_separation = debug_line_spacing
	_screen_debug.outline_size = debug_font_outline
	_screen_debug.default_font_color = debug_default_font_color
	_screen_debug.display_color = debug_background_color
	_screen_debug.display_opacity = debug_background_opacity
	_screen_debug.display_size = debug_background_size
	_screen_debug.display_position = debug_background_position
	_screen_debug.margin = debug_background_padding

	add_child.call_deferred(_screen_debug)
	await _screen_debug.tree_entered

	for expr in expressions:
		if expr:
			expr._init_owner(self)

func _process(delta):
	if _is_development():
		return
	_accum += delta
	if _accum < update_interval:
		return
	_accum = 0.0
	
	_update_debug()
#endregion


#region INTERNAL EXECUTION
func _update_debug() -> void:
	if Engine.is_editor_hint():
		return

	if not debug_active:
		return

	if not is_instance_valid(debug_target):
		return

	if not is_instance_valid(_screen_debug):
		return

	_screen_debug.clear_text()
		
	if debug_title.strip_edges() != "":
		_screen_debug.append_text("[color=%s][b]%s[/b][/color]\n" % [debug_default_font_color.to_html(), debug_title])

	_handle_quick_expressions()
	_handle_expressions()


func _handle_quick_expressions() -> void:
	for key in quick_expressions:
		var expr := quick_expressions[key]
		if not expr:
			continue

		var result := _resolve_expression(debug_target, expr)
		if result == null:
			continue

		var value := _format_value(result)

		if value.contains("tool mode"):
			value = ""

		_screen_debug.append_text(
			"[color=%s][b]%s[/b]:[/color] [color=%s]%s[/color]\n"
			% [
				debug_key_font_color.to_html(),
				key,
				debug_value_font_color.to_html(),
				value
			]
		)


func _handle_expressions() -> void:
	for expr_data in expressions:
		if not expr_data:
			continue

		if not expr_data.visible:
			continue
			
		var key := expr_data.label
		var expr := expr_data.expression


		if not expr:
			continue

		var result := _resolve_expression(debug_target, expr)
		if result == null:
			continue

		var value := _format_value(result)

		if value.contains("tool mode"):
			value = ""

		_screen_debug.append_text(
			"[color=%s][b]%s[/b]:[/color] [color=%s]%s[/color]\n"
			% [
				debug_key_font_color.to_html(),
				key,
				debug_value_font_color.to_html(),
				value
			]
		)


func _parse_param(text: String) -> Variant:
	text = text.strip_edges()

	# ======= Intercept constructors específicos =======
	# Vector2(x,y)
	if text.begins_with("Vector2(") and text.ends_with(")"):
		var args = text.substr(8, text.length() - 9).split(",")
		if args.size() == 2:
			return Vector2(args[0].to_float(), args[1].to_float())
		return null

	# Vector3(x,y,z)
	if text.begins_with("Vector3(") and text.ends_with(")"):
		var args = text.substr(8, text.length() - 9).split(",")
		if args.size() == 3:
			return Vector3(args[0].to_float(), args[1].to_float(), args[2].to_float())
		return null

	# Vector4(x,y,z,w)
	if text.begins_with("Vector4(") and text.ends_with(")"):
		var args = text.substr(8, text.length() - 9).split(",")
		if args.size() == 4:
			return Vector4(
				args[0].to_float(),
				args[1].to_float(),
				args[2].to_float(),
				args[3].to_float()
			)
		return null

	# ======= Avaliar literais simples com Expression =======
	var expr := Expression.new()
	var err := expr.parse(text)
	if err == OK:
		var res := expr.execute([debug_target], null)
		if not expr.has_execute_failed():
			return res

	# ======= Fallback opcional para prefixos antigos =======
	if text.begins_with("String:"):
		return text.replace("String:", "")
	if text.begins_with("int:"):
		return int(text.replace("int:", ""))
	if text.begins_with("float:"):
		return float(text.replace("float:", ""))
	if text.begins_with("bool:"):
		var v := text.replace("bool:", "")
		if v == "true":
			return true
		if v == "false":
			return false
		return null

	return null


func _parse_method_args(text: String) -> Array:
	var args: Array = []
	var current := ""
	var depth := 0

	for c in text:
		if c == "(":
			depth += 1
		elif c == ")":
			depth -= 1
		elif c == "," and depth == 0:
			args.append(current.strip_edges())
			current = ""
			continue
		current += c

	if current.strip_edges() != "":
		args.append(current.strip_edges())

	# agora processa cada argumento
	for i in range(args.size()):
		var parsed := _parse_param(args[i])
		if parsed == null:
			parsed = _resolve_expression(debug_target, args[i])
		if parsed == null:
			#push_warning("Invalid param: %s" % args[i])
			continue
		args[i] = parsed

	return args


func _format_value(v: Variant) -> String:
	match typeof(v):
		TYPE_FLOAT:
			return _format_float(v, floats_decimal_places)

		TYPE_INT:
			return str(v)

		TYPE_BOOL:
			return str(v)

		TYPE_VECTOR2:
			return _format_vector2(v, floats_vector_places)

		TYPE_VECTOR3:
			return _format_vector3(v, floats_vector_places)

		TYPE_VECTOR4:
			return _format_vector4(v, floats_vector_places)

		_:
			return str(v)


func _format_float(v: float, decimals: int) -> String:
	decimals = clamp(decimals, 0, 10)
	var format := "%." + str(decimals) + "f"
	return format % v


func _format_vector2(v: Vector2, decimals: int) -> String:
	return "Vector2(%s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals)
	]


func _format_vector3(v: Vector3, decimals: int) -> String:
	return "Vector3(%s, %s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals),
		_format_float(v.z, decimals)
	]


func _format_vector4(v: Vector4, decimals: int) -> String:
	return "Vector4(%s, %s, %s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals),
		_format_float(v.z, decimals),
		_format_float(v.w, decimals)
	]


func _is_array_index(part: String) -> bool:
	return part.contains("[") and part.ends_with("]")


func _is_method_call(part: String) -> bool:
	return part.contains("(") and part.ends_with(")")


func _resolve_expression(base: Variant, expression: String) -> Variant:
	var parts := expression.split(".")
	var current: Variant = base

	for part in parts:
		current = _resolve_part(current, part)
		if current == null:
			return null

	return current


func _resolve_part(current: Variant, part: String) -> Variant:
	if current == null:
		return null

	if _is_array_index(part):
		return _resolve_index(current, part)

	if _is_method_call(part):
		return _resolve_method_call(current, part)

	if current is Object:
		return _resolve_object_member(current, part)

	return _resolve_builtin(current, part)


func _resolve_index(current: Variant, part: String) -> Variant:
	var open := part.find("[")
	var base_part := part.substr(0, open)
	var col := part.substr(open + 1, part.length() - open - 2)
	var index := part.substr(open + 1, part.length() - open - 2).to_int()

	if base_part != "":
		current = _resolve_part(current, base_part)
		if current == null:
			return null

	if current is Array:
		if index < 0 or index >= current.size():
			# push_warning("Array index out of bounds: %d" % index)
			return null
		return current[index]

	if current is Dictionary:
		if not current.has(col):
			# push_warning("Dictionary key not found: %s" % col)
			return null
		return current[col]

	#push_warning("Indexing supported only on Array")
	return null


func _resolve_method_call(current: Variant, part: String) -> Variant:
	var name := part.substr(0, part.find("("))
	var params_text := part.substr(part.find("(") + 1, part.length() - part.find("(") - 2)

	if not_allowed_methods.has(name):
		#push_warning("Method not allowed: %s" % name)
		return null

	var args := _parse_method_args(params_text)
	if args == null:
		return null

	if current is Object and current.has_method(name):
		return current.callv(name, args)

	match typeof(current):
		TYPE_VECTOR2:
			return _call_vector2_method(current, name, args)
		TYPE_VECTOR3:
			return _call_vector3_method(current, name, args)
		TYPE_VECTOR4:
			return _call_vector4_method(current, name, args)
		TYPE_BASIS:
			return _call_basis_method(current, name, args)
		TYPE_DICTIONARY:
			return _call_dictionary_method(current, name, args)

	#push_warning("Method not found: %s" % name)
	return null


func _resolve_object_member(obj: Object, part: String) -> Variant:
	if part in obj:
		return obj.get(part)

	var getter := "get_" + part
	if obj.has_method(getter):
		return obj.call(getter)

	#push_warning("Property not found: %s" % part)
	return null


func _resolve_builtin(value: Variant, part: String) -> Variant:
	match typeof(value):
		TYPE_VECTOR2:
			return _resolve_vector2(value, part)
		TYPE_VECTOR3:
			return _resolve_vector3(value, part)
		TYPE_VECTOR4:
			return _resolve_vector4(value, part)
		TYPE_TRANSFORM3D:
			return _resolve_transform3d(value, part)
		TYPE_BASIS:
			return _resolve_basis(value, part)
		TYPE_ARRAY:
			return _resolve_array(value, part)
		TYPE_DICTIONARY:
			return _resolve_dictionary(value, part)

	#push_warning("Cannot resolve part: %s" % part)
	return null


func _resolve_vector2(v: Vector2, part: String) -> Variant:
	match part:
		"x": return v.x
		"y": return v.y
		"length": return v.length()
		"length_squared": return v.length_squared()
		"normalized": return v.normalized()
	return null


func _resolve_vector3(v: Vector3, part: String) -> Variant:
	match part:
		"x": return v.x
		"y": return v.y
		"z": return v.z
		"length": return v.length()
		"length_squared": return v.length_squared()
		"normalized": return v.normalized()
	return null


func _resolve_vector4(v: Vector4, part: String) -> Variant:
	match part:
		"x": return v.x
		"y": return v.y
		"z": return v.z
		"w": return v.w
		"length": return v.length()
	return null


func _resolve_transform3d(t: Transform3D, part: String) -> Variant:
	match part:
		"origin":
			return t.origin
		"basis":
			return t.basis
	return null


func _resolve_basis(b: Basis, part: String) -> Variant:
	match part:
		"x":
			return b.x
		"y":
			return b.y
		"z":
			return b.z
	return null


func _resolve_array(arr: Array, part: String) -> Variant:
	match part:
		"size":
			return arr.size()
		"length":
			return arr.size() # alias opcional
	return null


func _resolve_dictionary(d: Dictionary, part: String) -> Variant:
	match part:
		"size":
			return d.size()
		"length":
			return d.size() # alias opcional
	return null


func _call_vector2_method(v: Vector2, name: String, args: Array) -> Variant:
	match name:
		"dot":
			if args.size() != 1 or not (args[0] is Vector2):
				return null
			return v.dot(args[0])
		"distance_to":
			if args.size() != 1 or not (args[0] is Vector2):
				return null
			return v.distance_to(args[0])
		"angle_to":
			if args.size() != 1 or not (args[0] is Vector2):
				return null
			return v.angle_to(args[0])
		"normalized":
			if args.size() != 0:
				return null
			return v.normalized()
		"length":
			if args.size() != 0:
				return null
			return v.length()
		"length_squared":
			if args.size() != 0:
				return null
			return v.length_squared()
		_:
			return null


func _call_vector3_method(v: Vector3, name: String, args: Array) -> Variant:
	match name:
		"dot":
			if args.size() != 1 or not (args[0] is Vector3):
				return null
			return v.dot(args[0])
		"cross":
			if args.size() != 1 or not (args[0] is Vector3):
				return null
			return v.cross(args[0])
		"distance_to":
			if args.size() != 1 or not (args[0] is Vector3):
				return null
			return v.distance_to(args[0])
		"angle_to":
			if args.size() != 1 or not (args[0] is Vector3):
				return null
			return v.angle_to(args[0])
		"direction_to":
			if args.size() != 1 or not (args[0] is Vector3):
				return null
			return v.direction_to(args[0])
		"normalized":
			if args.size() != 0:
				return null
			return v.normalized()
		"length":
			if args.size() != 0:
				return null
			return v.length()
		"length_squared":
			if args.size() != 0:
				return null
			return v.length_squared()
		_:
			return null


func _call_vector4_method(v: Vector4, name: String, args: Array) -> Variant:
	match name:
		"dot":
			if args.size() != 1 or not (args[0] is Vector4):
				return null
			return v.dot(args[0])
		"length":
			if args.size() != 0:
				return null
			return v.length()
		"length_squared":
			if args.size() != 0:
				return null
			return v.length_squared()
		_:
			return null


func _call_basis_method(b: Basis, name: String, args: Array) -> Variant:
	if args.size() > 0:
		return null

	match name:
		"x": return b.x
		"y": return b.y
		"z": return b.z
	return null


func _call_dictionary_method(d: Dictionary, name: String, args: Array) -> Variant:
	match name:
		"get":
			if args.size() != 1:
				return null
			return d.get(args[0])
	return null

#endregion


#region PRIVATE METHODS
func _is_development() -> bool:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		set_process(false)
		set_physics_process(false)
		debug_active = false

		if not _warned:
			push_warning(
				"ScreenDebug detected in RELEASE build. " +
				"Remove it before publishing the game."
			)
			_warned = true

		return true
	return false
#endregion
