extends Area2D
class_name Building

const HOVER_OUTLINE_COLOR := Color(1.0, 0.82, 0.15, 1.0)
const HOVER_OUTLINE_OFFSETS := [
	Vector2(-2, -2),
	Vector2(0, -2),
	Vector2(2, -2),
	Vector2(-2, 0),
	Vector2(2, 0),
	Vector2(-2, 2),
	Vector2(0, 2),
	Vector2(2, 2),
]

@onready var sprite: AnimatedSprite2D = $sprite

@export var radar_icon: Texture2D

@export_category("Fuel")
@export var has_fuel := false
@export var max_fuel := 100
@export var fuel_used := 1

@export_category("Health")
@export var has_health := false
@export var max_health := 100
@export var current_health := 100


var current_fuel : int = max_fuel

var is_placed := true
var building_owner : Player

## Gesetzt, wenn das Gebäude per PlayerHand platziert wurde (für Rückzahlung beim Abreißen).
var can_salvage_refund := false
var salvage_blueprint_key: BluePrintData.Keys = BluePrintData.Keys.Generator
var hover_outline_root: Node2D = null
var hover_outline_sprites: Array[AnimatedSprite2D] = []
var hover_outline_active := false

func _ready() -> void:
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	_create_hover_outline_sprites()
	set_building_hover(false)

func _process(delta: float) -> void:
	_sync_hover_outline_sprites()
	if has_fuel:
		fuel_check()
	if has_health:
		check_health()

func fuel_check() -> void:
	if current_fuel >= max_fuel/3:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color.WHITE, 0.5)
		
	elif current_fuel <= max_fuel/3 and current_fuel > 0:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color("#aeaeae"), 0.5)
		
	else:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color("#df7d7d"), 0.5)

func _collect_fuel(area: Area2D) -> void:
	if has_fuel:
		if area is ItemCrystal:
			if current_fuel <= max_fuel:
				current_fuel += area.value
				area.destroy()


func check_health() -> void:
	if current_health <= 0:
		death()
		set_process(false)

func repair_health(amount: int) -> void:
	if has_health:
		if current_health + amount < max_health:
			current_health += amount
		else:
			current_health = max_health

func _enter_tree() -> void:
	GlobalGame.Buildings.append(self)
	current_health = max_health

func _exit_tree() -> void:
	GlobalGame.Buildings.erase(self)

##has to be overwritten for better deads
func death():
	queue_free()

func get_hit():
	pass

func set_building_hover(active: bool) -> void:
	hover_outline_active = active
	var sprite_visible := is_instance_valid(sprite) and sprite.visible

	if is_instance_valid(hover_outline_root):
		hover_outline_root.visible = active and sprite_visible

func set_salvage_hover(active: bool) -> void:
	set_building_hover(active)

func _create_hover_outline_sprites() -> void:
	if not is_instance_valid(sprite) or is_instance_valid(hover_outline_root):
		return

	hover_outline_root = Node2D.new()
	hover_outline_root.name = "HoverOutline"
	hover_outline_root.visible = false
	hover_outline_root.z_index = sprite.z_index
	hover_outline_root.z_as_relative = sprite.z_as_relative
	add_child(hover_outline_root)
	move_child(hover_outline_root, sprite.get_index())

	for offset in HOVER_OUTLINE_OFFSETS:
		var outline_sprite := AnimatedSprite2D.new()
		outline_sprite.name = "OutlinePart"
		outline_sprite.position = offset
		outline_sprite.self_modulate = HOVER_OUTLINE_COLOR
		var outline_material := CanvasItemMaterial.new()
		outline_material.light_mode = 1
		outline_sprite.material = outline_material
		hover_outline_root.add_child(outline_sprite)
		hover_outline_sprites.append(outline_sprite)

	_sync_hover_outline_sprites()

func _sync_hover_outline_sprites() -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(hover_outline_root):
		return

	hover_outline_root.position = sprite.position
	hover_outline_root.rotation = sprite.rotation
	hover_outline_root.scale = sprite.scale
	hover_outline_root.visible = hover_outline_active and sprite.visible

	for outline_sprite in hover_outline_sprites:
		if not is_instance_valid(outline_sprite):
			continue

		outline_sprite.sprite_frames = sprite.sprite_frames
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
			outline_sprite.animation = sprite.animation
			outline_sprite.set_frame_and_progress(sprite.frame, sprite.frame_progress)

		outline_sprite.centered = sprite.centered
		outline_sprite.offset = sprite.offset
		outline_sprite.flip_h = sprite.flip_h
		outline_sprite.flip_v = sprite.flip_v
		outline_sprite.speed_scale = sprite.speed_scale
		outline_sprite.visible = sprite.visible
