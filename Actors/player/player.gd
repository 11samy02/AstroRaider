extends CharacterBody2D
class_name Player

enum states {
	Default,
	Build,
}

var current_state := states.Default
@export var radar_icon: Texture2D
@export var movement: Node
@export var shader_effects: PlayerShaderEffects
@onready var check_for_ground: ShapeCast2D = $Rays/check_for_ground
@onready var check_for_destroyable_ground: ShapeCast2D = $Rays/check_for_destroyable_ground
@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_anim: AnimationPlayer = $Sprite/sprite_anim
@onready var bohrer_holder: Node2D = $bohrer_holder
@onready var bohrer_hit_coll: CollisionShape2D = $BohrerHitBox/bohrer_hit_coll
@onready var damage_sound: Audio2D = $Sounds/Damage
@onready var bohrer_sound: Audio2D = $Sounds/BohrerSound
@onready var live_indikator: Audio2D = $Sounds/LiveIndikator

@export var landing_anim_name: Array[String]
var gravity_dir := Vector2.DOWN
@export var player_id := 0
@export var controller_id := 0
@export var character_build_id := 0
@export var perk_manager: PerkManager
var is_bohrer_active := false
var deadzone := 0.25
@export var stats: Stats
var collected_crystals: Array[ItemCrystal] = []
var can_take_damage := true
var invuln_task_running := false
var shield_damage_block := false
var hit_iframe_duration := 1.0

## Loads the stats from the selected saved build
func _ready() -> void:
	if character_build_id < PlayerDataBuilds.player_saved_res.saved_builds.size():
		stats = PlayerDataBuilds.player_saved_res.saved_builds[character_build_id].stats
	else:
		print("No Player Build was found with the ID ", character_build_id)
	_refresh_damage_state()

## Updates the player movement and shader effects
func _physics_process(_delta: float) -> void:
	move_and_slide()
	shader_effects.run()

## Plays the hit feedback animation and damage sound
func get_hit_anim() -> void:
	var tween := create_tween()
	sprite.scale = Vector2(1.5, 1.5)
	damage_sound.play_sound()
	shader_effects.play_hit_flash(tween)
	tween.parallel().tween_property(sprite, "scale", Vector2(1, 1), 0.2)
	sprite_anim.play("damaged", -1, stats.get_hit_animation_speed())


## Removes invalid crystal references from the collected list
func clear_collected_null() -> void:
	for i in range(collected_crystals.size() - 1, -1, -1):
		if collected_crystals[i] == null:
			collected_crystals.remove_at(i)

## Applies knockback through the movement component
func get_knockback(dir: Vector2, strength: float) -> void:
	movement.get_knockback(dir, strength)

## Starts temporary hit invulnerability without interfering with shield protection
func trigger_invincibility_frames() -> void:
	if invuln_task_running:
		return
	invuln_task_running = true
	_refresh_damage_state()
	get_hit_anim()
	await get_tree().create_timer(stats.get_hit_iframe_duration_total()).timeout
	invuln_task_running = false
	_refresh_damage_state()

## Enables or disables the damage block coming from the shield
func set_shield_damage_block(enabled: bool) -> void:
	shield_damage_block = enabled
	_refresh_damage_state()

## Recomputes whether the player can currently take damage
func _refresh_damage_state() -> void:
	can_take_damage = not shield_damage_block and not invuln_task_running
