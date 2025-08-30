extends Area2D
class_name EnemyProjectile

const EXPLODE = preload("res://Projectiles/explosions/fire_ball_explode.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particle: GPUParticles2D = $particle

@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 600
@export var dir := Vector2.ZERO


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is Player:
			area.get_hit(atk_resource)
			GSignals.CAM_shake_effect.emit()
			set_physics_process(false)
			animation_player.play("hit")
		if area.entity is BarrierShield:
			area.get_hit(atk_resource)
			set_physics_process(false)
			animation_player.play("hit")
	if area is BuildingHitbox:
		if area.entity is Building:
			area.get_hit(atk_resource)
			set_physics_process(false)
			animation_player.play("hit")


func _physics_process(delta: float) -> void:
	look_at(dir)
	translate(dir * speed * delta)


func _on_lifetime_timeout() -> void:
	set_physics_process(false)
	particle.emitting = false
	animation_player.play("hit")

func spawn_explosion() -> void:
	var explode = EXPLODE.instantiate()
	explode.global_position = global_position
	explode.emitting = true
	get_parent().add_child(explode)

func _destroy() -> void:
	call_deferred("queue_free")
