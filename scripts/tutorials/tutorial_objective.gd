extends CanvasLayer
class_name ObjectiveTaskUI

const PANEL_COLOR := Color(0.035, 0.043, 0.058, 0.92)
const BORDER_COLOR := Color(0.60, 0.72, 0.86, 0.28)
const EXP_COLOR := Color(0.72, 1.0, 0.66, 1.0)

@export_category("Content")
@export var objective_kind: TaskResource.TaskKind = TaskResource.TaskKind.TUTORIAL
@export var title_override := ""
@export_multiline var task_text := "OBJECTIVE"
@export var challenge_exp := 0

@export_category("Text Colors")
@export var title_color := Color(0.67, 0.77, 0.88, 1.0)
@export var task_color := Color(0.98, 0.92, 0.74, 1.0)

@onready var root: Control = $Control
@onready var panel: PanelContainer = $Control/ObjectivePanel
@onready var margin: MarginContainer = $Control/ObjectivePanel/Margin
@onready var stack: VBoxContainer = $Control/ObjectivePanel/Margin/Stack
@onready var title_row: HBoxContainer = $Control/ObjectivePanel/Margin/Stack/TitleRow
@onready var accent: ColorRect = $Control/ObjectivePanel/Margin/Stack/TitleRow/Accent
@onready var title_label: Label = $Control/ObjectivePanel/Margin/Stack/TitleRow/TitleLabel
@onready var title_spacer: Control = $Control/ObjectivePanel/Margin/Stack/TitleRow/TitleSpacer
@onready var exp_label: Label = $Control/ObjectivePanel/Margin/Stack/TitleRow/ExpLabel
@onready var objective_label: RichTextLabel = $Control/ObjectivePanel/Margin/Stack/ObjectiveLabel


func _ready() -> void:
	apply_settings()
	hide_objective()


func apply_settings() -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _build_panel_style())

	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	stack.add_theme_constant_override("separation", 8)
	title_row.add_theme_constant_override("separation", 8)

	accent.custom_minimum_size = Vector2(6, 18)
	accent.color = _get_kind_accent_color()

	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title_label.text = get_title_text()
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", title_color)

	exp_label.add_theme_font_size_override("font_size", 12)
	exp_label.add_theme_color_override("font_color", EXP_COLOR)

	objective_label.bbcode_enabled = true
	objective_label.fit_content = true
	objective_label.scroll_active = false
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("normal_font_size", 20)
	objective_label.add_theme_color_override("default_color", task_color)
	objective_label.text = task_text

	_update_exp_visibility()


func setup(
	kind: TaskResource.TaskKind,
	text: String,
	exp: int = 0,
	title: String = ""
) -> void:
	objective_kind = kind
	task_text = text
	challenge_exp = 0 if objective_kind == TaskResource.TaskKind.TUTORIAL else exp
	title_override = title
	apply_settings()


func set_objective_text(text: String) -> void:
	task_text = text
	objective_label.text = text


func show_objective(text: String = "") -> void:
	if text != "":
		set_objective_text(text)
	_update_exp_visibility()
	panel.show()


func show_tutorial_objective(text: String) -> void:
	setup(TaskResource.TaskKind.TUTORIAL, text, 0)
	show_objective()


func show_task(text: String, title: String = "") -> void:
	setup(TaskResource.TaskKind.TASK, text, 0, title)
	show_objective()


func show_challenge(kind: TaskResource.TaskKind, text: String, exp: int, title: String = "") -> void:
	setup(kind, text, exp, title)
	show_objective()


func show_task_resource(task: TaskResource, values: Dictionary = {}) -> void:
	if not is_instance_valid(task):
		hide_objective()
		return

	title_color = task.title_color
	task_color = task.task_color
	setup(task.task_kind, task.get_display_text(values), task.get_reward_exp(), task.title_override)
	show_objective()


func hide_objective() -> void:
	panel.hide()


func is_objective_visible() -> bool:
	return panel.visible


func get_title_text() -> String:
	if title_override.strip_edges() != "":
		return title_override
	return TaskResource.get_default_title_for_kind(objective_kind)


func _update_exp_visibility() -> void:
	var should_show_exp := objective_kind != TaskResource.TaskKind.TUTORIAL and challenge_exp > 0
	exp_label.visible = should_show_exp
	if should_show_exp:
		exp_label.text = "+%s EXP" % challenge_exp
	else:
		exp_label.text = ""


func _get_kind_accent_color() -> Color:
	return TaskResource.get_accent_color_for_kind(objective_kind)


func _build_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	return style
