extends Area2D
class_name PlayerProjectile


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particle: GPUParticles2D = $particle

@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 500
@export var dir := Vector2.ZERO
@export var hp := 1

@export var player : Player = null


func _ready() -> void:
	look_at(dir)
	if is_instance_valid(player):
		hp += player.stats.added_Projectile_lives
	animation_player.play("appearing")

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			var new_atk_resource : AttackResource = atk_resource.duplicate()
			if is_instance_valid(player):
				new_atk_resource.damage += player.stats.added_projectile_damage
				new_atk_resource.crit_chance += player.stats.crit_chance + player.stats.added_crit_chance
				new_atk_resource.has_stun = player.stats.has_stun_active
				new_atk_resource.stun_strength = player.stats.stun_strength
				
			area.get_hit(new_atk_resource, player)
			hp -= 1
			if hp <= 0:
				set_physics_process(false)
				area.entity.get_knockback(dir, new_atk_resource.knockback)
				animation_player.play("hit")


func _physics_process(delta: float) -> void:
	look_at(dir)
	translate(dir * speed * delta)


func _on_lifetime_timeout() -> void:
	set_physics_process(false)
	particle.emitting = false
	animation_player.play("hit")
