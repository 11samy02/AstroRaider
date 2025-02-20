extends Area2D
class_name PlayerProjectile


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particle: GPUParticles2D = $particle

@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 500
@export var dir := Vector2.ZERO

@export var parent : Player = null

func _ready() -> void:
	look_at(dir)
	atk_resource.crit_chance = 1
	animation_player.play("appearing")

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			area.get_hit(atk_resource, parent)
			set_physics_process(false)
			area.entity.get_knockback(dir, atk_resource.knockback)
			animation_player.play("hit")


func _physics_process(delta: float) -> void:
	look_at(dir)
	translate(dir * speed * delta)


func _on_lifetime_timeout() -> void:
	set_physics_process(false)
	particle.emitting = false
	animation_player.play("hit")
