extends Node2D
class_name BossEntity

const DAMAGE_PARTICLE = preload("res://Visuel Feedback Tutorial/visuel_counter.tscn")

@export var stats : BossStats
@export var hitbox : Area2D
@export var healtbar : BossHealthBar


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	var is_crit = is_crit_attack(attack)
	healtbar.get_damage(calculate_real_damage(attack), is_crit)

func calculate_real_damage(attack: AttackResource, is_crit : bool = false) -> int:
	var damage_part = DAMAGE_PARTICLE.instantiate()
	var damage : int = attack.damage
	if is_crit:
		damage_part.text = str(attack.damage*3)
		damage_part.color = Color("#ff5400")
		damage_part.global_position = self.global_position
		get_parent().add_child(damage_part)
		return attack.damage * 3
	return damage

func is_crit_attack(attack: AttackResource) -> bool:
	var random_num = randf_range(0.00,100.00)
	if random_num <= stats.default_crit_chance + attack.crit_chance:
		return true
	return false
