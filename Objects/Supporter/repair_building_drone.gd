extends Area2D
class_name RepairBuildingDrones

const REPAIR_BUILDING_DRONE = preload("res://Objects/Supporter/repair_building_drone.tscn")

@onready var cooldown: Timer = $cooldown

var station : RepairDroneStation

var building_to_repair : Building

var heal_distance := 10.00
var heal_amount := 1
var heal_time := 0.5
var current_heal_time := 0.5

var sleep_distance := 30.00

var speed := 200.00
var velocity: Vector2 = Vector2.ZERO
var acceleration: float = 500.0
var friction: float = 5.0

static func create(new_station: RepairDroneStation) -> RepairBuildingDrones:
	var instance = REPAIR_BUILDING_DRONE.instantiate()
	instance.station = new_station
	instance.global_position = new_station.global_position
	return instance

func _ready() -> void:
	add_to_group("repair_drones")


enum state_mashine {
	Sleep,
	Flying,
	Healing,
}

var state := state_mashine.Sleep

func set_building_to_repair(building : Building) -> void:
	if building.current_health < building.max_health:
		building_to_repair = building
		state = state_mashine.Flying
	else:
		state = state_mashine.Sleep

func has_building() -> bool:
	return(is_instance_valid(building_to_repair))

func _process(delta: float) -> void:
	if state == state_mashine.Healing:
		heal_building(delta)
	if state == state_mashine.Flying:
		fly_to_building(delta)
	if state == state_mashine.Sleep:
		sleep(delta)


func heal_building(delta) -> void:
	if is_instance_valid(building_to_repair):
		if building_to_repair.current_health < building_to_repair.max_health:
			if global_position.distance_to(building_to_repair.global_position) < heal_distance:
				if cooldown.is_stopped():
					cooldown.start()
				if current_heal_time <= 0:
					building_to_repair.repair_health(heal_amount)
					current_heal_time = heal_time
				else:
					current_heal_time -= delta
	else:
		state = state_mashine.Sleep

func fly_to_building(delta: float) -> void:
	if not is_instance_valid(building_to_repair):
		state = state_mashine.Sleep
		return
	
	var to_target = building_to_repair.global_position - global_position
	
	if to_target.length() < heal_distance:
		state = state_mashine.Healing
		return
	
	move(delta, to_target.normalized(), building_to_repair.global_position)



func sleep(delta) -> void:
	if not is_instance_valid(station):
		destroy()
		return
	
	var to_target = station.global_position - global_position
	
	if to_target.length() < sleep_distance:
		await get_tree().create_timer(cooldown.wait_time).timeout
		building_to_repair = null
		return
	
	move(delta, to_target.normalized(), station.global_position)


func move(delta : float, direction : Vector2, target_position : Vector2) -> void:
	var distance_to_target = global_position.distance_to(target_position)
	var slow_down_distance = 150.0
	var min_speed = 50.0
	
	var speed_factor = clamp(distance_to_target / slow_down_distance, 0.3, 1.0)
	var target_speed = lerp(min_speed, speed, speed_factor)
	
	var deviation_strength = 0.3
	var noise_offset_x = sin(Time.get_ticks_msec() * 0.001 + hash(self)) * deviation_strength
	var noise_offset_y = cos(Time.get_ticks_msec() * 0.001 + hash(self) + 100.0) * deviation_strength
	
	var deviation = Vector2(noise_offset_x, noise_offset_y)
	var final_direction = (direction + deviation).normalized()
	
	var avoidance = avoid_drones()
	final_direction += avoidance.normalized() * 0.6
	
	velocity = velocity.lerp(final_direction * target_speed, 0.05)
	global_position += velocity * delta




func avoid_drones() -> Vector2:
	var avoidance_force := Vector2.ZERO
	var avoidance_radius := 20.0
	var repulsion_strength := 50.0

	for drone in get_tree().get_nodes_in_group("repair_drones"):
		if drone != self and global_position.distance_to(drone.global_position) < avoidance_radius:
			avoidance_force += (global_position - drone.global_position).normalized() * repulsion_strength
	
	return avoidance_force


func destroy():
	queue_free()


func _on_cooldown_timeout() -> void:
	state = state_mashine.Sleep
