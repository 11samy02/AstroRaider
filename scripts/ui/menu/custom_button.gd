@tool
extends Button
class_name CustomButton

@export var custom_icon: Texture2D
@export var custom_text: String

@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var text_label: Label = $HBoxContainer/text_label

func _ready() -> void:
	set_details()
	mouse_entered.connect(_update_colors)
	mouse_exited.connect(_update_colors)
	button_down.connect(_update_colors)
	button_up.connect(_update_colors)
	focus_entered.connect(_update_colors)
	focus_exited.connect(_update_colors)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_details()

func set_details() -> void:
	texture_rect.set_texture(custom_icon)
	text_label.set_text(custom_text)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_DRAW:
		_update_colors()

func _update_colors() -> void:
	if not is_node_ready():
		return
	var font_color: Color
	var icon_color: Color
	if is_disabled():
		font_color = get_theme_color("font_disabled_color", "Button")
		icon_color = get_theme_color("icon_disabled_color", "Button")
	elif button_pressed:
		font_color = get_theme_color("font_pressed_color", "Button")
		icon_color = get_theme_color("icon_pressed_color", "Button")
	elif is_hovered():
		font_color = get_theme_color("font_hover_color", "Button")
		icon_color = get_theme_color("icon_hover_color", "Button")
	else:
		font_color = get_theme_color("font_color", "Button")
		icon_color = get_theme_color("icon_normal_color", "Button")
	text_label.add_theme_color_override("font_color", font_color)
	texture_rect.modulate = icon_color
