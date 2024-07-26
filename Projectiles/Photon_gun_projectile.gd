extends Area2D
class_name PlayerProjectile

const EXPLODE = ""

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particle: CPUParticles2D = $particle

@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 600
@export var dir := Vector2.ZERO


func _ready() -> void:
	look_at(dir)
	animation_player.play("appearing")

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			area.get_hit(atk_resource)
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

func spawn_explosion() -> void:
	#var explode = EXPLODE.instantiate()
	#explode.global_position = global_position
	#explode.emitting = true
	#get_parent().add_child(explode)
	pass
