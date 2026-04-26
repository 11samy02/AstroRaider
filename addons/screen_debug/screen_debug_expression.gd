@tool
@icon("res://addons/screen_debug/icon.svg")

## Resource for creating a new expression to be used with the Screen Debug node.
class_name ScreenDebugExpression extends Resource

## Turns visibility on or off.
@export var visible: bool = true

## Label of the expression on the screen.
@export var label: String

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
@export_multiline var expression: String


var _owner: ScreenDebug


func _init_owner(p_owner: ScreenDebug) -> void:
	_owner = p_owner
