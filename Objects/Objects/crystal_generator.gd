extends Building
class_name CrystalGenerator

@onready var collect_crystal: AudioStreamPlayer2D = $Sounds/CollectCrystal

var Ores: Dictionary = {}

var player_list : Array[Player] = []

const VISUEL_PATH = preload("res://Visuel Feedback Tutorial/visuel_path.tscn")
const COUNTER_PARTICLE = preload("res://Visuel Feedback Tutorial/visuel_counter.tscn")

func _enter_tree() -> void:
	GSignals.PLA_collects_crystal.connect(check_if_player_has_crstal)
	GlobalGame.Buildings.append(self)

func _on_area_entered(area: Area2D) -> void:
	if area is ItemCrystal:
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == area.player_who_collected:
				player_res.crystal_count += area.value
				break
		var counter_part = COUNTER_PARTICLE.instantiate()
		counter_part.duration = 1.5
		counter_part.color = Color.GREEN
		counter_part.outline_color = Color.BLACK
		counter_part.text = "+" + str(area.value) + "$"
		counter_part.global_position = self.global_position
		counter_part.distance = randi_range(30,50)
		get_parent().add_child(counter_part)
		area.destroy()
		collect_crystal.play()
	
	if area is OreTemplate:
		if Ores.has(area.Ore_type):
			Ores[area.Ore_type] += 1
		else:
			Ores.get_or_add(area.Ore_type, 0)
			Ores[area.Ore_type] += 1
		area.destroy()
		collect_crystal.play()


func _on_check_player_nearby_body_entered(body: Node2D) -> void:
	if body is Player:
		player_list.append(body)


func _on_check_player_nearby_body_exited(body: Node2D) -> void:
	if body is Player:
		player_list.erase(body)

func _process(delta: float) -> void:
	check_player_input()


func check_player_input() -> void:
	for player in player_list:
		if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) or Input.is_action_just_pressed("interact"):
			GSignals.PLA_open_skill_tree.emit(player)


func check_if_player_has_crstal() -> void:
	for player_res:PlayerResource in GlobalGame.Players:
		if player_res.crystal_count <= 0 and !player_res.has_a_path:
			var visuel_path = VISUEL_PATH.instantiate()
			visuel_path.from_player = player_res.player
			visuel_path.to_obj = self
			get_parent().add_child(visuel_path)
			player_res.has_a_path = true
