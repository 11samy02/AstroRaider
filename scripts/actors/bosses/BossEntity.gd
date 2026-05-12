extends Node2D
class_name BossEntity

signal phase_changed(phase_index: int, phase_data: BossPhaseData)

const DAMAGE_PARTICLE = preload("res://scenes/tutorials/visual_feedback/visuel_counter.tscn")

@export var stats : BossStats
@export var hitbox : Area2D
@export var healtbar : BossHealthBar
@export var phases: Array[BossPhaseData] = []

var is_dead := false
var current_phase_index := -1
var current_phase: BossPhaseData = null


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

	_refresh_current_phase(true)


func _process(_delta: float) -> void:
	if is_instance_valid(stats) and stats.current_hp <= 0:
		die()
		return

	_refresh_current_phase()


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if is_dead or not is_instance_valid(stats):
		return
	
	var is_crit = is_crit_attack(attack)
	var damage := calculate_real_damage(attack, is_crit, who_attacked)
	
	if is_instance_valid(healtbar):
		healtbar.get_damage(damage, is_crit)
	else:
		stats.current_hp = max(stats.current_hp - damage, 0)
	
	get_hit_anim()
	
	if stats.current_hp <= 0:
		die()
	else:
		_refresh_current_phase()

func calculate_real_damage(attack: AttackResource, is_crit : bool = false, _who_attacked: CharacterBody2D = null) -> int:
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


func get_current_phase() -> BossPhaseData:
	return current_phase


func get_current_phase_index() -> int:
	return current_phase_index


func _on_phase_changed(_phase_index: int, _phase_data: BossPhaseData) -> void:
	pass


func _refresh_current_phase(force: bool = false) -> void:
	if phases.is_empty() or not is_instance_valid(stats):
		if force:
			current_phase_index = -1
			current_phase = null
		return

	var next_phase_index := _get_phase_index_for_health()
	if next_phase_index < 0:
		return

	if not force and next_phase_index == current_phase_index:
		return

	current_phase_index = next_phase_index
	current_phase = phases[current_phase_index]
	_on_phase_changed(current_phase_index, current_phase)
	phase_changed.emit(current_phase_index, current_phase)


func _get_phase_index_for_health() -> int:
	if phases.is_empty() or not is_instance_valid(stats):
		return -1

	var hp_ratio := 1.0
	if stats.Max_HP > 0:
		hp_ratio = clampf(float(stats.current_hp) / float(stats.Max_HP), 0.0, 1.0)

	var selected_index := -1
	var selected_threshold := INF
	var highest_index := -1
	var highest_threshold := -INF

	for i in range(phases.size()):
		var phase := phases[i]
		if phase == null:
			continue

		var threshold := clampf(phase.health_ratio, 0.0, 1.0)
		if threshold > highest_threshold:
			highest_threshold = threshold
			highest_index = i

		if hp_ratio <= threshold and threshold < selected_threshold:
			selected_threshold = threshold
			selected_index = i

	if selected_index >= 0:
		return selected_index

	return highest_index


func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	GlobalGame.Bosses.erase(self)
	queue_free()


func _exit_tree() -> void:
	GlobalGame.Bosses.erase(self)
