extends BossEntity


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("aktivat_perk"):
		var attack := AttackResource.new()
		attack.damage = 100
		attack.crit_chance = 30
		get_hit(attack)
