extends Node2D
class_name BossEntity

const DAMAGE_PARTICLE = preload("res://scenes/tutorials/visual_feedback/visuel_counter.tscn")

@export var stats : BossStats
@export var hitbox : Area2D
@export var healtbar : BossHealthBar

var is_dead := false


func _enter_tree() -> void:
	if self not in GlobalGame.Bosses:
		GlobalGame.Bosses.append(self)


func _ready() -> void:
	if is_instance_valid(stats):
		stats.reset_runtime_stats()
	
	if is_instance_valid(hitbox) and hitbox is Hitbox:
		hitbox.entity = self
	
	if is_instance_valid(healtbar):
		healtbar.setup(self, stats)


func _process(_delta: float) -> void:
	if is_instance_valid(stats) and stats.current_hp <= 0:
		die()


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if is_dead or not is_instance_valid(stats):
		return
	
	var is_crit = is_crit_attack(attack)
	var damage := calculate_real_damage(attack, is_crit)
	
	if is_instance_valid(healtbar):
		healtbar.get_damage(damage, is_crit)
	else:
		stats.current_hp = max(stats.current_hp - damage, 0)
	
	get_hit_anim()
	
	if stats.current_hp <= 0:
		die()

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


func get_radar_icon() -> Texture2D:
	if is_instance_valid(stats):
		return stats.radar_icon
	return null


func get_hit_anim() -> void:
	pass


func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	GlobalGame.Bosses.erase(self)
	queue_free()


func _exit_tree() -> void:
	GlobalGame.Bosses.erase(self)
