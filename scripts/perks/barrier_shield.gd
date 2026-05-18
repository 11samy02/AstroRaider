extends Hitbox
class_name BarrierShield

var Health := 25
var MaxHealth := 25

@export var atk_resource: AttackResource

var _shield_mat: ShaderMaterial = null
var _is_destroying := false


func is_destroying() -> bool:
	return _is_destroying


## Caches the shield material for hit flash effects
func _ready() -> void:
	_shield_mat = self.material as ShaderMaterial

	if MaxHealth <= 0:
		MaxHealth = Health

	_emit_shield_changed()


## Enables full damage blocking while the shield exists
func _enter_tree() -> void:
	if entity is Player:
		entity.set_active_barrier_shield(self)

		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == entity:
				player_res.shield_res.has_shield = true
				break


## Keeps the shield centered on its owner
func _physics_process(_delta: float) -> void:
	if entity:
		global_position = entity.global_position


## Applies incoming damage to the shield instead of the player
func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if _is_destroying:
		return

	Health = maxi(Health - attack.damage, 0)

	_emit_shield_changed()
	_flash_hit()

	if Health <= 0 and not $AnimationPlayer.is_playing():
		_is_destroying = true
		if entity is Player:
			entity.clear_active_barrier_shield(self)
		GSignals.PERK_barrier_shield_destroyed.emit()
		$AnimationPlayer.play("destroy")


## Emits the current shield state to the UI
func _emit_shield_changed() -> void:
	if entity is Player:
		GSignals.PERK_barrier_shield_changed.emit(entity, Health, MaxHealth)


## Flashes the shield red on hit
func _flash_hit() -> void:
	if not is_instance_valid(_shield_mat):
		return

	_shield_mat.set_shader_parameter("hit_flash", 1.0)

	var tween := create_tween()
	tween.tween_method(_set_hit_flash, 1.0, 0.0, 0.2)


## Updates the shader hit flash value
func _set_hit_flash(value: float) -> void:
	if is_instance_valid(_shield_mat):
		_shield_mat.set_shader_parameter("hit_flash", value)


## Pushes enemies away when they overlap the shield
func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox and area.entity is EnemyBaseTemplate:
		area.entity.get_knockback((area.global_position - global_position).normalized(), atk_resource.knockback)


## Removes the shield and restores normal damage rules
func destroy() -> void:
	if entity is Player:
		entity.clear_active_barrier_shield(self)

		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == entity:
				player_res.shield_res.has_shield = false
				break

		GSignals.PERK_barrier_shield_changed.emit(entity, 0, MaxHealth)

	queue_free()
