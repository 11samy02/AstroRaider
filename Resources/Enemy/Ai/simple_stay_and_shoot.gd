extends Entity_Ai

var has_attacked := false

@export var brake: float = 800.0            # Abbremsrate in px/s²
@export var stop_threshold: float = 30.0    # Unter dieser Speed wird geschossen

# Optional: Wenn gesetzt, werden Projektile hier einsortiert (ansonsten Fallbacks, s. unten)
@export var projectiles_holder: NodePath

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	attack(delta)
	parent.move_and_slide()

func attack(delta: float) -> void:
	if has_attacked:
		return

	# Sanft abbremsen
	parent.velocity = parent.velocity.move_toward(Vector2.ZERO, brake * delta)

	# Sobald fast still -> schießen
	if parent.velocity.length() < stop_threshold:
		has_attacked = true

		if parent.stats.projectile:
			if parent.Shoot_sound:
				parent.Shoot_sound.play_sound()

			var ps: PackedScene = parent.stats.projectile
			var prj := ps.instantiate()

			if prj is EnemyProjectile:
				var tgt := parent.get_closest_target()
				var dir := (tgt - parent.global_position).normalized()

				prj.dir = dir
				if parent.stats.ranged_attack:
					prj.atk_resource = parent.stats.ranged_attack.duplicate()
				prj.global_position = parent.global_position

				var holder := _projectiles_parent()
				holder.add_child(prj)

		parent.reset_to_last_state()
		has_attacked = false


func _projectiles_parent() -> Node:
	if projectiles_holder != NodePath():
		var n := get_node_or_null(projectiles_holder)
		if n:
			return n
	return _safe_projectile_parent()

func _safe_projectile_parent() -> Node:
	var tree := get_tree()
	var root := tree.current_scene if tree.current_scene != null else tree.root
	var holder := root.get_node_or_null("Projectiles")
	return holder if holder != null else root
