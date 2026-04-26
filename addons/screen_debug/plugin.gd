@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_custom_type("ScreenDebug", "CanvasLayer", preload("res://addons/screen_debug/screen_debug.gd"), preload("res://addons/screen_debug/icon.svg"))
	add_custom_type("ScreenDebugExpression", "Resource", preload("res://addons/screen_debug/screen_debug_expression.gd"), preload("res://addons/screen_debug/icon.svg"))


func _disable_plugin() -> void:
	remove_custom_type("ScreenDebug")
	remove_custom_type("ScreenDebugExpression")
