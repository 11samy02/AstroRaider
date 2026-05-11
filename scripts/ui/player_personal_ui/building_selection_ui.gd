@tool
extends Control
class_name BuildingSelectButton

var tween: Tween
var inner_default_pos: Vector2

@export var texture: Texture2D
@export var label_text: int
@export var key : BluePrintData.Keys
@export var shortcut : Key = Key.KEY_NONE
@export var texture_margin: Vector4

@onready var texture_rect: TextureRect = $"Building-selection-ui/MarginContainer/TextureRect"
@onready var keybind_label: Label = $"Building-selection-ui/Panel/keybind_label"
@onready var margin_container: MarginContainer = $"Building-selection-ui/MarginContainer"
@onready var building_selection_ui: Button = $"Building-selection-ui"




func _ready() -> void:
	tween = create_tween()
	set_textures()
	connect_signals()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == shortcut:
			_on_pressed()


func connect_signals() -> void:
	building_selection_ui.connect("mouse_entered", _on_mouse_entered)
	building_selection_ui.connect("mouse_exited", _on_mouse_exited)
	building_selection_ui.connect("pressed", _on_pressed)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_textures()

func set_textures() -> void:
	if !is_instance_valid(texture):
		return
	texture_rect.texture = texture
	keybind_label.text = str(label_text)
	margin_container.add_theme_constant_override("margin_left", texture_margin.x)
	margin_container.add_theme_constant_override("margin_top", texture_margin.y)
	margin_container.add_theme_constant_override("margin_bottom", texture_margin.z)
	margin_container.add_theme_constant_override("margin_right", texture_margin.w)

func _on_mouse_entered() -> void:
	GSignals.BUI_allow_to_place.emit(true)
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)
	
	tween.tween_property(building_selection_ui, "position", inner_default_pos + Vector2(0, -15), 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	GSignals.BUI_allow_to_place.emit(false)
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel(true)

	tween.tween_property(building_selection_ui, "position", inner_default_pos, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_pressed() -> void:
	GSignals.BUI_BUILDING_select_building.emit(key)
