extends PerkBuild

var math : SimplefySettingMath = SimplefySettingMath.new()

const ITEM_CRYSTAL = preload("res://Objects/Collectable/crystal.tscn")

func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(spawn_more_coins)


func spawn_more_coins(pos: Vector2) -> void:
	math.min_value = 0
	math.max_value = get_value()
	for i in range(math.min_value, math.max_value):
		var new_crystal: ItemCrystal = ITEM_CRYSTAL.instantiate()
		
		new_crystal.global_position = pos + Vector2(randi_range(-10,10), randi_range(-10,10))
		new_crystal.is_first_one = false
		
		get_parent().add_child(new_crystal)

func _exit_tree() -> void:
	pass
