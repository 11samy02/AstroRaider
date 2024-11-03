extends Hitbox
class_name BarrierShield

var Health := 25
@export var atk_resource: AttackResource


func _enter_tree() -> void:
	if entity is Player:
		entity.can_take_damage = false


func _physics_process(delta: float) -> void:
	global_position = entity.global_position

func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	Health -= attack.damage
	
	if Health <= 0:
		GSignals.PERK_barrier_shield_destroyed.emit(self)
		$AnimationPlayer.play("destroy")

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			area.entity.get_knockback((area.global_position - global_position).normalized(), atk_resource.knockback)

func _exit_tree() -> void:
	if entity is Player:
		entity.can_take_damage = true

func destroy():
	queue_free()
