extends PerkBuild

const ITEM_CRYSTAL = preload("res://Collectable/crystal.tscn")

## Passive: spawns bonus crystals when player collects one
func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(_on_crystal_collected)
	super()

func _on_crystal_collected(pos: Vector2) -> void:
	if !has_unlocked:
		return
	var new_crystal: ItemCrystal = ITEM_CRYSTAL.instantiate()
	var rand := randi_range(1, get_value())
	new_crystal.global_position = pos + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	new_crystal.value += rand
	new_crystal.is_first_one = false
	new_crystal.mass += rand / 10.0
	get_parent().call_deferred("add_child", new_crystal)
