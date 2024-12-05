extends Entity_Ai

var has_attacked := false

func _physics_process(delta: float) -> void:
	attack(delta)

func attack(delta) -> void:
	match parent.state:
		state:
			if !has_attacked:
				parent.velocity = lerp(parent.velocity, Vector2.ZERO, delta * parent.stats.speed)
				
				if abs(parent.velocity) < Vector2(30,30):
					has_attacked = true
					if parent.stats.projectile != null:
						if parent.Shoot_sound != null:
							parent.Shoot_sound.play_sound()
						var projectile = parent.stats.projectile.instantiate()
						if projectile is EnemyProjectile:
							projectile.dir = (parent.get_closest_target() - parent.global_position).normalized()
							projectile.atk_resource = parent.stats.ranged_attack.duplicate()
							projectile.global_position = parent.global_position
							parent.get_parent().add_child(projectile)
							
							parent.reset_to_last_state()
							has_attacked = false
