extends PerkBuild

var math : SimplefySettingMath = SimplefySettingMath.new()

const ITEM_CRYSTAL = preload("res://Collectable/crystal.tscn")

func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(spawn_more_coins)


func spawn_more_coins(pos: Vector2) -> void:
	math.min_value = 1
	math.max_value = get_value()
	
	var new_crystal: ItemCrystal = ITEM_CRYSTAL.instantiate()
	
	new_crystal.global_position = pos + Vector2(randi_range(-10,10), randi_range(-10,10))
	var rand = randi_range(math.min_value, math.max_value)
	new_crystal.value += rand
	new_crystal.is_first_one = false
	new_crystal.mass += rand / 10.0
	get_parent().add_child(new_crystal)

func _exit_tree() -> void:
	pass
