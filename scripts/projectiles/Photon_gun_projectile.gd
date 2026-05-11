extends Area2D
class_name PlayerProjectile

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var trail: Trail
@export var enemy_detector_area: EnemyDetectorArea
@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 500.0
@export var dir := Vector2.ZERO
@export var hp := 1
@export var player: Player = null

var _last_rotation_dir := Vector2.ZERO


## Initializes projectile direction, stats, and spawn animation
func _ready() -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()
		_last_rotation_dir = dir
	
	if is_instance_valid(player):
		hp += int(round(player.stats.get_projectile_lives_total()))
	
	set_physics_process(false)
	trail.visible = false
	
	animation_player.play("appearing")
	await animation_player.animation_finished
	
	trail.clear_trail()
	trail.visible = true
	set_physics_process(true)


## Applies projectile damage when colliding with an enemy
func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate or area.entity is BossEntity:
			var new_atk_resource: AttackResource = atk_resource.duplicate()
			
			if is_instance_valid(player):
				new_atk_resource.damage += player.stats.get_projectile_damage_total()
				new_atk_resource.crit_chance += player.stats.get_crit_chance_total()
				new_atk_resource.has_stun = player.stats.has_stun_active
				new_atk_resource.stun_strength = player.stats.stun_strength
			
			area.get_hit(new_atk_resource, player)
			
			if area.entity is EnemyBaseTemplate:
				area.entity.get_knockback(dir, new_atk_resource.knockback)
			
			if is_instance_valid(enemy_detector_area):
				enemy_detector_area.mark_enemy_as_hit(area.entity)
			
			hp -= 1
			
			if hp <= 0:
				set_physics_process(false)
				trail.clear_trail()
				animation_player.play("hit")


## Moves the projectile and updates its rotation
func _physics_process(delta: float) -> void:
	if dir == Vector2.ZERO:
		return
	
	if dir != _last_rotation_dir:
		rotation = dir.angle()
		_last_rotation_dir = dir

	global_position += dir * speed * delta


## Ends the projectile when its lifetime expires
func _on_lifetime_timeout() -> void:
	set_physics_process(false)
	trail.clear_trail()
	animation_player.play("hit")
