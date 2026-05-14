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
@export var selected_suit: SuitData.SuitKeys = SuitData.SuitKeys.Trailblazer
@export var perk_manager: PerkManager
var is_bohrer_active := false
var deadzone := 0.25
var stats: Stats = Stats.new()
var suit_data: SuitData
var collected_crystals: Array[ItemCrystal] = []
var can_take_damage := true
var invuln_task_running := false
var shield_damage_block := false
var hit_iframe_duration := 1.0

## Loads the selected suit before child nodes cache player stats.
func _enter_tree() -> void:
	_load_saved_build()
	_load_stats_from_selected_suit()


## Initializes runtime state after the player entered the scene.
func _ready() -> void:
	_refresh_damage_state()


## Returns the currently selected suit resource.
func get_selected_suit_data() -> SuitData:
	if is_instance_valid(suit_data) and suit_data.Key == selected_suit:
		return suit_data
	suit_data = SuitData.load_suit_res(selected_suit)
	return suit_data


## Applies the selected saved build's suit key when a build exists.
func _load_saved_build() -> void:
	if character_build_id >= PlayerDataBuilds.player_saved_res.saved_builds.size():
		print("No Player Build was found with the ID ", character_build_id)
		return

	var saved_build := PlayerDataBuilds.player_saved_res.saved_builds[character_build_id]
	selected_suit = saved_build.selected_suit


## Rebuilds the player's runtime stats from the selected suit.
func _load_stats_from_selected_suit() -> void:
	var selected_suit_data := get_selected_suit_data()
	if not is_instance_valid(selected_suit_data) or not selected_suit_data.has_unlocked:
		stats = Stats.new()
		return

	var runtime_stats := selected_suit_data.stats.duplicate(true)
	if runtime_stats is Stats:
		stats = runtime_stats
	else:
		stats = Stats.new()

	_apply_saved_perks()


## Adds build-specific unlocked perks on top of the suit stats.
func _apply_saved_perks() -> void:
	if character_build_id >= PlayerDataBuilds.player_saved_res.saved_builds.size():
		return

	var saved_build := PlayerDataBuilds.player_saved_res.saved_builds[character_build_id]
	for perk in saved_build.unlocked_perks:
		if is_instance_valid(perk):
			var perk_copy := perk.duplicate(true)
			if perk_copy is Perk:
				stats.Perks.append(perk_copy)

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
