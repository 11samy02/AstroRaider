extends PerkBuild

var used_shield:= false

const BARRIER_SHIELD = preload("res://Objects/Perk Specials/barrier_shield.tscn")

static var shield_in_use_on: Array[BarrierShield]

func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(reset_shield)
	GSignals.PERK_barrier_shield_destroyed.connect(remove_shield)

func _process(delta: float) -> void:
	var shield_is_in_use := false
	for shield: BarrierShield in shield_in_use_on:
		if shield.entity == Player_Res.player:
			shield_is_in_use = true
	if Player_Res.current_health <= Player_Res.max_health/100 * 25 and !used_shield and !shield_is_in_use:
		used_shield = true
		activate_perk()

func activate_perk() -> void:
	var barrier_shield = BARRIER_SHIELD.instantiate()
	
	barrier_shield.entity = Player_Res.player
	barrier_shield.global_position = Player_Res.player.global_position
	barrier_shield.Health = get_value()
	get_parent().add_child(barrier_shield)
	shield_in_use_on.append(barrier_shield)

func reset_shield():
	used_shield = false

func remove_shield(shield: BarrierShield):
	if shield_in_use_on.has(shield):
		shield_in_use_on.erase(shield)

func _exit_tree() -> void:
	pass
