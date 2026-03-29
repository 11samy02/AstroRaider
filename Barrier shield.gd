extends Hitbox
class_name BarrierShield

var Health := 25
@export var atk_resource: AttackResource

var _shield_mat: ShaderMaterial = null

func _ready() -> void:
	_shield_mat = self.material as ShaderMaterial

func _enter_tree() -> void:
	if entity is Player:
		entity.can_take_damage = false
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == entity:
				player_res.shield_res.has_shield = true
				break

func _physics_process(delta: float) -> void:
	if entity:
		global_position = entity.global_position

func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	Health -= attack.damage
	_flash_hit()
	if Health <= 0 and !$AnimationPlayer.is_playing():
		GSignals.PERK_barrier_shield_destroyed.emit()
		$AnimationPlayer.play("destroy")

## Flashes the shield red on hit
func _flash_hit() -> void:
	if !is_instance_valid(_shield_mat):
		return
	_shield_mat.set_shader_parameter("hit_flash", 1.0)
	var tween := create_tween()
	tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.2)

func _set_hit_flash(value: float) -> void:
	if is_instance_valid(_shield_mat):
		_shield_mat.set_shader_parameter("hit_flash", value)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox and area.entity is EnemyBaseTemplate:
		area.entity.get_knockback((area.global_position - global_position).normalized(), atk_resource.knockback)

func destroy() -> void:
	if entity is Player:
		entity.can_take_damage = true
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == entity:
				player_res.shield_res.has_shield = false
				break
	queue_free()
