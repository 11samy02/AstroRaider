extends Building
class_name RepairDroneStation

@onready var collision_detection: CollisionShape2D = $BuildingDetector/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var max_drones_count := 2
var drones : Array[RepairBuildingDrones] = []

@export var max_range := 500.00
var building_list : Array[Building] = []

func _ready() -> void:
	set_range()

func _process(delta: float) -> void:
	sort_list()
	spawn_drones()
	sign_buildings()

func set_range() -> void:
	collision_detection.shape.radius = max_range



func _on_building_detector_area_entered(area: Area2D) -> void:
	if area == self:
		return
	if area is Building:
		if area.has_health:
			building_list.append(area)


func _on_building_detector_area_exited(area: Area2D) -> void:
	if area == self:
		return
	if area is Building:
		if area.has_health:
			building_list.erase(area)


func sort_list() -> void:
	building_list.sort_custom(building_sort_on_health)

func building_sort_on_health(a: Building, b: Building) -> bool:
	return (float(a.current_health) / float(a.max_health)) < (float(b.current_health) / float(b.max_health))

func get_hit():
	animation_player.play("hit")
	await( animation_player.animation_finished )


func spawn_drones() -> void:
	if drones.size() < max_drones_count:
		var instance : RepairBuildingDrones = RepairBuildingDrones.create(self)
		drones.append(instance)
		get_parent().add_child(instance)

func sign_buildings() -> void:
	var used_buildings : Array[Building] = []
	
	for drone in drones:
		if drone.has_building():
			used_buildings.append(drone.building_to_repair)
	
	for drone in drones:
		if !drone.has_building():
			for building in building_list:
				if building not in used_buildings:
					drone.set_building_to_repair(building)
					used_buildings.append(building)
					break
