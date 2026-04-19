extends CharacterBody2D
class_name SentinelDrone

signal died(drone: SentinelDrone)

enum DroneTier {
	SMALL,
	MEDIUM,
	HEAVY,
}

@export var player: Player
@export var perk_owner: PerkBuild
@export var projectile_scene: PackedScene

@export var tier: DroneTier = DroneTier.SMALL
@export var max_hp: int = 10
@export var current_hp: int = 10
@export var damage: int = 1
@export var fire_rate: float = 1.0
@export var explosion_damage: int = 5
@export var spawn_offset: Vector2 = Vector2.ZERO

@export var small_sprite: AnimatedSprite2D
@export var medium_sprite: AnimatedSprite2D
@export var heavy_sprite: AnimatedSprite2D
@export var hitbox: Hitbox

@export var movement: Node
@export var combat: Node

var is_dead := false
var target: EnemyBaseTemplate = null

func _ready() -> void:
	if is_instance_valid(movement):
		movement.drone = self

	if is_instance_valid(combat):
		combat.drone = self

	if is_instance_valid(hitbox):
		hitbox.entity = self

	_apply_visual_tier()
	_register_as_support()

	if not GSignals.HIT_take_Damage.is_connected(_on_global_hit_take_damage):
		GSignals.HIT_take_Damage.connect(_on_global_hit_take_damage)

func _exit_tree() -> void:
	_unregister_as_support()

	if GSignals.HIT_take_Damage.is_connected(_on_global_hit_take_damage):
		GSignals.HIT_take_Damage.disconnect(_on_global_hit_take_damage)

func create(source_perk: PerkBuild, new_projectile_scene: PackedScene, new_spawn_offset: Vector2) -> void:
	perk_owner = source_perk
	player = source_perk.player
	projectile_scene = new_projectile_scene
	spawn_offset = new_spawn_offset

	_apply_values_from_perk()

	if is_inside_tree():
		if is_instance_valid(hitbox):
			hitbox.entity = self
		_apply_visual_tier()
		_register_as_support()

func _apply_values_from_perk() -> void:
	if perk_owner == null:
		return

	if not perk_owner.has_method("get_drone_tier"):
		return

	tier = perk_owner.get_drone_tier()
	max_hp = perk_owner.get_drone_hp()
	current_hp = max_hp
	damage = perk_owner.get_drone_damage()
	fire_rate = perk_owner.get_drone_fire_rate()
	explosion_damage = perk_owner.get_drone_explosion_damage()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		queue_free()
		return

	if is_instance_valid(combat):
		target = combat.get_best_target()

	if is_instance_valid(movement):
		movement.tick(delta)

	move_and_slide()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	_play_hit_blink()
	
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	_unregister_as_support()
	_explode()
	died.emit(self)
	queue_free()

func _explode() -> void:
	_damage_enemies_in_radius()
	_damage_environment_in_radius()

func _damage_enemies_in_radius() -> void:
	var radius := _get_explosion_radius()

	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		GSignals.HIT_take_Damage.emit(enemy, explosion_damage, 0.0)

func _damage_environment_in_radius() -> void:
	var radius := _get_explosion_radius()
	var points := 12
	var pos_array: Array[Vector2] = [global_position]

	for i in range(points):
		var angle := (TAU / float(points)) * float(i)
		pos_array.append(global_position + Vector2.RIGHT.rotated(angle) * radius)

	GSignals.ENV_destroy_tile.emit(pos_array, explosion_damage)

func _get_explosion_radius() -> float:
	match tier:
		DroneTier.SMALL:
			return 28.0
		DroneTier.MEDIUM:
			return 40.0
		DroneTier.HEAVY:
			return 56.0
		_:
			return 28.0

func _apply_visual_tier() -> void:
	if is_instance_valid(small_sprite):
		small_sprite.visible = false
	if is_instance_valid(medium_sprite):
		medium_sprite.visible = false
	if is_instance_valid(heavy_sprite):
		heavy_sprite.visible = false

	match tier:
		DroneTier.SMALL:
			if is_instance_valid(small_sprite):
				small_sprite.visible = true
				small_sprite.play()
		DroneTier.MEDIUM:
			if is_instance_valid(medium_sprite):
				medium_sprite.visible = true
				medium_sprite.play()
		DroneTier.HEAVY:
			if is_instance_valid(heavy_sprite):
				heavy_sprite.visible = true
				heavy_sprite.play()

func _register_as_support() -> void:
	if self not in GlobalGame.Player_Support:
		GlobalGame.Player_Support.append(self)

func _unregister_as_support() -> void:
	GlobalGame.Player_Support.erase(self)

func _on_global_hit_take_damage(entity: CharacterBody2D, final_damage: int, crit: float) -> void:
	if entity != self:
		return
	take_damage(final_damage)

func _play_hit_blink() -> void:
	if material == null:
		return
	if not material is ShaderMaterial:
		return

	var mat := material as ShaderMaterial
	mat.set_shader_parameter("blink_color", Color.WHITE)
	mat.set_shader_parameter("blink_strength", 1.0)

	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/blink_strength", 0.0, 0.10)
