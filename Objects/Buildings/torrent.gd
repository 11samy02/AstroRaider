extends Building

@onready var enemy_detector_area: EnemyDetectorArea = $EnemyDetectorArea
@onready var shoot_sound: Audio2D = $ShootSound

const PROJECTILE = preload("res://Projectiles/Photon_gun_projectile.tscn")

@export var atk_res : AttackResource

var accuracy := 0.0

func _on_shoot_time_timeout() -> void:
	if !enemy_detector_area.Enemy_list.is_empty():
		attack()


func attack() -> void:
	if current_fuel > 0:
		if is_instance_valid(enemy_detector_area.Enemy_list[0]):
			var enemy := enemy_detector_area.Enemy_list[0]
			var projectile: PlayerProjectile = PROJECTILE.instantiate()
			projectile.atk_resource = atk_res
			
			var projectile_speed := projectile.speed
			var enemy_velocity := enemy.velocity
			var direction_to_enemy := enemy.global_position - self.global_position
			var time_to_enemy := direction_to_enemy.length() / projectile_speed
			var future_enemy_position := enemy.global_position + enemy_velocity * time_to_enemy
			var random_offset := Vector2(randf() - 0.5, randf() - 0.5) * (1 - accuracy) * 200
			
			projectile.dir = (future_enemy_position - self.global_position).normalized()
			
			projectile.global_position = self.global_position
			get_parent().add_child(projectile)
			shoot_sound.play_sound()
			current_fuel -= fuel_used

func fuel_check():
	if current_fuel >= max_fuel/3:
		var tween = create_tween()
		tween.tween_property(sprite,"speed_scale",1, 0.5)
		
	elif current_fuel <= max_fuel/3 and current_fuel > 0:
		var tween = create_tween()
		tween.tween_property(sprite,"speed_scale",0.75, 0.5)
		
	else:
		var tween = create_tween()
		tween.tween_property(sprite,"speed_scale",0.5, 0.5)
	super()
