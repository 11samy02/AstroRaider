extends PerkBuild

var used_shield := false
var has_shield := false
var active_shield : BarrierShield
const BARRIER_SHIELD = preload("res://Objects/Perk Specials/barrier_shield.tscn")

func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(reset_shield)
	GSignals.PERK_barrier_shield_destroyed.connect(remove_shield)

func activate_perk() -> void:
	if !has_shield and !used_shield and !is_instance_valid(active_shield):
		var shield_instance = BARRIER_SHIELD.instantiate()
		has_shield = true
		used_shield = true
		active_shield = shield_instance
		shield_instance.entity = Player_Res.player
		shield_instance.global_position = Player_Res.player.global_position
		shield_instance.Health = get_value()
		Player_Res.player.get_parent().add_child(shield_instance)

func reset_shield() -> void:
	used_shield = false

func remove_shield(shield: BarrierShield) -> void:
	if !is_instance_valid(active_shield) and shield == active_shield:
		has_shield = false
		active_shield = null

func _exit_tree() -> void:
	pass
