@tool

extends Panel


@onready var margin_container: MarginContainer = $MarginContainer
@onready var rich_text_label: RichTextLabel = $MarginContainer/RichTextLabel


@export var enable_bbcode: bool = true: set = set_enable_bbcode
@export var fit_content: bool = true: set = set_fit_content
@export var scroll_active: bool = true: set = set_scroll_active
@export var default_font_color: Color = Color.WHITE: set = set_default_font_color
@export_range(0.1, 50.0, 0.1, "or_greater") var normal_font_size: float = 50.0: set = set_normal_font_size
@export_range(0.1, 50.0, 0.1, "or_greater") var bold_font_size: float = 50.0: set = set_bold_font_size
@export_range(0.0, 50.0, 0.1, "or_greater") var line_separation: float = 50.0: set = set_line_separation
@export_range(0.0, 50.0, 0.1, "or_greater") var outline_size: float = 0.0: set = set_outline_size
@export var display_size: Vector2 = Vector2(500, 250): set = set_display_size
@export var display_position: Vector2 = Vector2.ZERO: set = set_display_position
@export_range(0.1, 50.0, 0.1, "or_greater") var margin: float = 10: set = set_margin
@export_color_no_alpha() var display_color: Color = Color.BLACK: set = set_display_color
@export_range(0.0, 1.0, 0.001) var display_opacity: float = 0.3: set = set_display_opacity


var _style_display: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	_style_display = StyleBoxFlat.new()
	add_theme_stylebox_override("panel", _style_display)

	set_enable_bbcode(enable_bbcode)
	set_fit_content(fit_content)
	set_scroll_active(scroll_active)
	set_default_font_color(default_font_color)
	set_normal_font_size(normal_font_size)
	set_bold_font_size(bold_font_size)
	set_margin(margin)
	set_display_size(display_size)
	set_display_color(display_color)
	set_display_opacity(display_opacity)
	set_line_separation(line_separation)
	set_outline_size(outline_size)
	set_display_position(display_position)
	

func set_text(value: String) -> void:
	if is_instance_valid(rich_text_label):
		rich_text_label.text = value


func get_text() -> String:
	return rich_text_label.text


func clear_text() -> void:
	if is_instance_valid(rich_text_label):
		rich_text_label.clear()
		
		
func append_text(value: String) -> void:
	if is_instance_valid(rich_text_label):
		rich_text_label.append_text("[color=%s]%s[/color]" % [default_font_color, value])
	
	
func set_display_position(value: Vector2) -> void:
	display_position = value
	position = value
	
	
func set_outline_size(value: float) -> void:
	outline_size = value
	if is_instance_valid(rich_text_label):
		rich_text_label.add_theme_constant_override("outline_size", value)


func set_line_separation(value: float) -> void:
	line_separation = value
	if is_instance_valid(rich_text_label):
		rich_text_label.add_theme_constant_override("line_separation", value)
	
	
func set_enable_bbcode(value: bool) -> void:
	enable_bbcode = value
	if is_instance_valid(rich_text_label):
		rich_text_label.bbcode_enabled = value
	

func set_fit_content(value: bool) -> void:
	fit_content = value
	if is_instance_valid(rich_text_label):
		rich_text_label.fit_content = value
	
	
func set_scroll_active(value: bool) -> void:
	scroll_active = value
	if is_instance_valid(rich_text_label):
		rich_text_label.scroll_active = value
	
	
func set_default_font_color(value: Color) -> void:
	default_font_color = value
	if is_instance_valid(rich_text_label):
		rich_text_label.add_theme_color_override("default_color", value)
	
	
func set_normal_font_size(value: float) -> void:
	normal_font_size = value
	if is_instance_valid(rich_text_label):
		rich_text_label.add_theme_font_size_override("normal_font_size", value)
	
	
func set_bold_font_size(value: float) -> void:
	bold_font_size = value
	if is_instance_valid(rich_text_label):
		rich_text_label.add_theme_font_size_override("bold_font_size", value)


func set_margin(value: float) -> void:
	margin = value
	if is_instance_valid(margin_container):
		margin_container.set("theme_override_constants/margin_left", value)
		margin_container.set("theme_override_constants/margin_top", value)
		margin_container.set("theme_override_constants/margin_right", value)
		margin_container.set("theme_override_constants/margin_bottom", value)


func set_display_size(value: Vector2) -> void:
	display_size = value
	size = value
	
	
func set_display_opacity(value: float) -> void:
	display_opacity = value
	if is_instance_valid(_style_display):
		_style_display.bg_color.a = value

	
func set_display_color(value: Color) -> void:
	display_color = value
	if is_instance_valid(_style_display):
		var c := value
		c.a = display_opacity
		_style_display.bg_color = c
