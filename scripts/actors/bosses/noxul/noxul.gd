extends BossEntity
class_name Noxul


@onready var scream_effect: AnimatedSprite2D = $scream_effect
@onready var charge_effect: AnimatedSprite2D = $charge_effect
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@export var movement: NoxulMovement
@export var behavior_tree: NoxulBehaviorTree
@export var tentacle_claws: BossTentacleClaws
@export var voidling_scene: PackedScene
@export var projectile_scene: PackedScene
@export var charge_attack: AttackResource = AttackResource.new()
@export_range(0, 8, 1) var minions_spawn_count: int = 3
@export_range(0, 24, 1) var max_active_voidlings: int = 6
@export var minion_spawn_radius: float = 48.0
@export var minion_spawn_random_offset: float = 12.0
@export var hit_blink_duration: float = 0.2
@export var contact_knockback_strength: float = 3.0
@export var contact_knockback_cooldown: float = 0.35
@export var projectile_spread_angle: float = 13.0
@export var projectile_spawn_offset: float = 30.0
@export_range(1, 24, 1) var projectile_count: int = 3

var _rng := RandomNumberGenerator.new()
var _summoned_voidlings: Array[EnemyBaseTemplate] = []
var _summon_triggered_this_scream := false
var _hit_blink_tween: Tween = null
var _contact_knockback_until: Dictionary = {}
var _charge_shot_active := false
var _current_noxul_phase: NoxulBossPhaseData = null


func _ready() -> void:
	super._ready()
	_rng.randomize()
	_resolve_behavior_nodes()
	_resolve_tentacle_claws()
	_apply_noxul_phase(_current_noxul_phase)
	if is_instance_valid(charge_effect):
		charge_effect.visible = false
	if is_instance_valid(anim) and anim.has_animation("idle"):
		anim.play("idle")


func request_scream_summon() -> bool:
	if not can_summon_voidlings():
		return false
	
	_summon_triggered_this_scream = false
	
	if is_instance_valid(anim) and anim.has_animation("scream"):
		anim.play("scream")
		return true
	
	start_scream_effect()
	return true


func finish_scream_summon() -> void:
	if is_instance_valid(anim) and anim.has_animation("idle"):
		anim.play("idle")


func request_charge_shot() -> bool:
	if _charge_shot_active or projectile_scene == null:
		return false
	
	var target := get_preferred_projectile_target()
	if not is_instance_valid(target):
		return false
	
	if is_instance_valid(movement):
		movement.face_position(target.global_position)
	
	_charge_shot_active = true
	_run_charge_shot(target.global_position)
	return true


func is_charge_shot_active() -> bool:
	return _charge_shot_active


func get_preferred_projectile_target() -> Node2D:
	var building_target := _get_priority_building_target()
	if is_instance_valid(building_target) and _should_target_building():
		return building_target

	var closest_player := _get_closest_player()
	if is_instance_valid(closest_player):
		return closest_player
	
	var closest_support := _get_closest_support()
	if is_instance_valid(closest_support):
		return closest_support

	return building_target


func get_closest_combat_target() -> Node2D:
	var closest_target: Node2D = null
	var closest_dist := INF
	
	for target: Node2D in _get_combat_targets():
		var dist := global_position.distance_to(target.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_target = target
	
	return closest_target


func get_hit_anim() -> void:
	var damage_material := _get_damage_material()
	if damage_material == null:
		return
	
	if _hit_blink_tween != null:
		_hit_blink_tween.kill()
	
	_set_damage_blink_strength(1.0)
	_hit_blink_tween = create_tween()
	_hit_blink_tween.tween_method(
		Callable(self, "_set_damage_blink_strength"),
		1.0,
		0.0,
		hit_blink_duration
	)


func calculate_real_damage(attack: AttackResource, is_crit: bool = false, who_attacked: CharacterBody2D = null) -> int:
	var damage := super.calculate_real_damage(attack, is_crit, who_attacked)
	if damage <= 0 or _current_noxul_phase == null:
		return damage

	var multiplier := _current_noxul_phase.incoming_damage_multiplier
	match attack.source_type:
		AttackResource.SourceType.BUILDING:
			multiplier *= _current_noxul_phase.building_damage_multiplier
		AttackResource.SourceType.PERK:
			multiplier *= _current_noxul_phase.perk_damage_multiplier
		AttackResource.SourceType.SUPPORT:
			multiplier *= _current_noxul_phase.support_damage_multiplier

	var final_damage = max(1, int(round(float(damage) * multiplier)))
	if _current_noxul_phase.max_damage_per_hit > 0:
		final_damage = min(final_damage, _current_noxul_phase.max_damage_per_hit)
	return final_damage


func start_scream_effect() -> void:
	if _summon_triggered_this_scream:
		return
	
	_summon_triggered_this_scream = true
	
	if is_instance_valid(scream_effect):
		scream_effect.stop()
		scream_effect.frame = 0
		scream_effect.frame_progress = 0.0
		scream_effect.play("default")
	summon_voidlings()


func _run_charge_shot(target_position: Vector2) -> void:
	if is_instance_valid(charge_effect):
		charge_effect.visible = true
		charge_effect.stop()
		charge_effect.frame = 0
		charge_effect.frame_progress = 0.0
		charge_effect.play("default")
		await charge_effect.animation_finished
		charge_effect.visible = false
	
	shoot_projectile_spread(target_position)
	_charge_shot_active = false


func shoot_projectile_spread(target_position: Vector2) -> void:
	if projectile_scene == null:
		return
	
	var base_dir := target_position - global_position
	if base_dir.length_squared() <= 0.001:
		base_dir = Vector2.RIGHT
	base_dir = base_dir.normalized()
	
	var count = max(1, projectile_count)
	
	if count == 1:
		_spawn_projectile(base_dir)
		return
	
	var total_spread := deg_to_rad(projectile_spread_angle)
	
	for i in range(count):
		var t := float(i) / float(count - 1) 
		var angle = lerp(-total_spread, total_spread, t)
		_spawn_projectile(base_dir.rotated(angle))


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate()
	if not projectile is EnemyProjectile:
		if projectile is Node:
			projectile.queue_free()
		return
	
	var enemy_projectile := projectile as EnemyProjectile
	enemy_projectile.dir = direction.normalized()
	enemy_projectile.global_position = charge_effect.global_position + enemy_projectile.dir * projectile_spawn_offset
	enemy_projectile.atk_resource = charge_attack.duplicate()
	_get_projectile_parent().add_child(enemy_projectile)


func _get_projectile_parent() -> Node:
	var root := get_tree().current_scene if get_tree().current_scene else get_tree().root
	if root.has_node("Projectiles"):
		return root.get_node("Projectiles")
	return root


func summon_voidlings(count: int = -1) -> void:
	if count < 0:
		count = minions_spawn_count
	
	_prune_summoned_voidlings()
	var available_slots := max_active_voidlings - _summoned_voidlings.size()
	count = min(count, available_slots)
	
	if voidling_scene == null or count <= 0:
		return
	
	var spawn_parent := get_parent()
	if spawn_parent == null:
		spawn_parent = get_tree().current_scene
	if spawn_parent == null:
		return
	
	for i in range(count):
		var voidling := voidling_scene.instantiate()
		if voidling == null:
			continue
		
		if "level" in voidling:
			voidling.level = floori(EntitySpawner.wave_count / EntitySpawner.enemy_levels_after)
		
		var angle := (TAU / float(max(1, count))) * float(i)
		angle += _rng.randf_range(-0.25, 0.25)
		var distance = max(0.0, minion_spawn_radius + _rng.randf_range(
			-minion_spawn_random_offset,
			minion_spawn_random_offset
		))

		spawn_parent.add_child(voidling)

		if voidling is Node2D:
			voidling.global_position = global_position + Vector2.RIGHT.rotated(angle) * distance
		
		if voidling is EnemyBaseTemplate:
			_summoned_voidlings.append(voidling)
			
			if voidling not in EnemyBaseTemplate.entity_list:
				EnemyBaseTemplate.entity_list.append(voidling)


func can_summon_voidlings() -> bool:
	if voidling_scene == null:
		return false
	
	_prune_summoned_voidlings()
	return _summoned_voidlings.size() < max_active_voidlings


func get_active_voidling_count() -> int:
	_prune_summoned_voidlings()
	return _summoned_voidlings.size()


func _resolve_behavior_nodes() -> void:
	if movement == null and has_node("Scripts/Movement"):
		movement = $Scripts/Movement as NoxulMovement
	if behavior_tree == null and has_node("Scripts/BehaviorTree"):
		behavior_tree = $Scripts/BehaviorTree as NoxulBehaviorTree
	
	if is_instance_valid(movement):
		movement.boss = self
		movement.sprite = sprite
		movement.scream_effect = scream_effect
		movement.charge_effect = charge_effect
	
	if is_instance_valid(behavior_tree):
		behavior_tree.boss = self
		behavior_tree.movement = movement


func _resolve_tentacle_claws() -> void:
	if tentacle_claws == null and has_node("TentacleClaws"):
		tentacle_claws = $TentacleClaws as BossTentacleClaws

	if is_instance_valid(tentacle_claws):
		tentacle_claws.boss = self


func _on_phase_changed(_phase_index: int, phase_data: BossPhaseData) -> void:
	var phase := phase_data as NoxulBossPhaseData
	if phase == null:
		return

	_current_noxul_phase = phase
	_apply_noxul_phase(phase)


func _apply_noxul_phase(phase: NoxulBossPhaseData) -> void:
	if phase == null:
		return

	projectile_count = phase.projectile_count
	projectile_spread_angle = phase.projectile_spread_angle
	minions_spawn_count = phase.minions_spawn_count
	max_active_voidlings = phase.max_active_voidlings

	if charge_attack != null:
		charge_attack.damage = phase.charge_damage
		charge_attack.knockback = phase.charge_knockback
		charge_attack.source_type = AttackResource.SourceType.BOSS

	if is_instance_valid(behavior_tree):
		behavior_tree.summon_cooldown = phase.summon_cooldown
		behavior_tree.summon_range = phase.summon_range
		behavior_tree.summon_recovery_time = phase.summon_recovery_time
		behavior_tree.shot_cooldown = phase.shot_cooldown
		behavior_tree.shot_range = phase.shot_range
		behavior_tree.shot_recovery_time = phase.shot_recovery_time
		behavior_tree.clamp_active_cooldowns_to_phase()

	if is_instance_valid(movement):
		movement.move_speed = phase.move_speed
		movement.acceleration = phase.acceleration
		movement.hover_distance = phase.hover_distance
		movement.orbit_weight = phase.orbit_weight

	if is_instance_valid(tentacle_claws):
		tentacle_claws.attack_range = phase.tentacle_attack_range
		tentacle_claws.attack_lunge_length = phase.tentacle_lunge_length
		tentacle_claws.attack_knockback_strength = phase.tentacle_knockback_strength
		tentacle_claws.attack_damage = phase.tentacle_attack_damage
		tentacle_claws.attack_cooldown_min = phase.tentacle_cooldown_min
		tentacle_claws.attack_cooldown_max = phase.tentacle_cooldown_max


func _prune_summoned_voidlings() -> void:
	for i in range(_summoned_voidlings.size() - 1, -1, -1):
		if not is_instance_valid(_summoned_voidlings[i]):
			_summoned_voidlings.remove_at(i)


func _set_damage_blink_strength(value: float) -> void:
	var damage_material := _get_damage_material()
	if damage_material != null:
		damage_material.set_shader_parameter("blink_strength", value)


func _get_damage_material() -> ShaderMaterial:
	if material is ShaderMaterial:
		return material as ShaderMaterial
	if is_instance_valid(sprite) and sprite.material is ShaderMaterial:
		return sprite.material as ShaderMaterial
	return null


func _on_hitbox_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null:
		return
	
	if hitbox.entity is SentinelDrone:
		var drone := hitbox.entity as SentinelDrone
		_damage_drone_on_contact(drone, hitbox)
		return
	
	if not hitbox.entity is Player:
		return
	
	var player := hitbox.entity as Player
	_knockback_player_on_contact(player)


func _knockback_player_on_contact(player: Player) -> void:
	if not is_instance_valid(player):
		return
	
	var player_id := player.get_instance_id()
	var now := Time.get_ticks_msec() * 0.001
	var next_allowed := float(_contact_knockback_until.get(player_id, 0.0))
	if next_allowed > now:
		return
	
	_contact_knockback_until[player_id] = now + contact_knockback_cooldown
	
	var dir := player.global_position - global_position
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	
	player.get_knockback(dir.normalized(), contact_knockback_strength)


func _damage_drone_on_contact(drone: SentinelDrone, drone_hitbox: Hitbox) -> void:
	if not is_instance_valid(drone) or not is_instance_valid(drone_hitbox):
		return
	
	var drone_id := drone.get_instance_id()
	var now := Time.get_ticks_msec() * 0.001
	var next_allowed := float(_contact_knockback_until.get(drone_id, 0.0))
	if next_allowed > now:
		return
	
	_contact_knockback_until[drone_id] = now + contact_knockback_cooldown
	
	if is_instance_valid(stats) and is_instance_valid(stats.attack):
		drone_hitbox.get_hit(stats.attack.duplicate())


func _get_closest_player() -> Player:
	var closest_player: Player = null
	var closest_dist := INF
	
	for player_res: PlayerResource in GlobalGame.Players:
		if not is_instance_valid(player_res.player):
			continue
		
		var dist := global_position.distance_to(player_res.player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_player = player_res.player
	
	return closest_player


func _get_closest_support() -> Node2D:
	var closest_support: Node2D = null
	var closest_dist := INF
	
	for support: Node2D in GlobalGame.Player_Support:
		if not is_instance_valid(support):
			continue
		
		var dist := global_position.distance_to(support.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_support = support
	
	return closest_support


func _should_target_building() -> bool:
	if _current_noxul_phase == null:
		return false

	return _rng.randf() <= _current_noxul_phase.building_target_chance


func _get_priority_building_target() -> Building:
	var best_building: Building = null
	var best_score := INF
	var max_range := 620.0
	if _current_noxul_phase != null:
		max_range = _current_noxul_phase.building_target_range

	for building: Building in GlobalGame.Buildings:
		if not is_instance_valid(building):
			continue
		if not building.has_health:
			continue

		var dist := global_position.distance_to(building.global_position)
		if dist > max_range:
			continue

		var score := dist
		if building is Torrent:
			score -= 220.0
		elif building is MetalGround:
			score -= 90.0

		if building.max_health > 0:
			var health_ratio := float(building.current_health) / float(building.max_health)
			score += health_ratio * 40.0

		if score < best_score:
			best_score = score
			best_building = building

	return best_building


func _get_combat_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	
	for player_res: PlayerResource in GlobalGame.Players:
		if is_instance_valid(player_res.player):
			targets.append(player_res.player)
	
	for support: Node2D in GlobalGame.Player_Support:
		if is_instance_valid(support):
			targets.append(support)

	for building: Building in GlobalGame.Buildings:
		if is_instance_valid(building) and building.has_health:
			targets.append(building)
	
	return targets
