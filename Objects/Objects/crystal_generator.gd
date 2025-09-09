extends Building
class_name CrystalGenerator

@onready var collect_crystal: AudioStreamPlayer2D = $Sounds/CollectCrystal
@onready var animation_player: AnimationPlayer = $AnimationPlayer

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
		collect_crystal.play_sound()
	
	if area is OreTemplate:
		for player_res : PlayerResource in GlobalGame.Players:
			if player_res.player == area.player_who_collected:
				var ore_name = area.Ores.keys()[area.Ore_type]
				if player_res.Ores.has(ore_name):
					player_res.Ores[ore_name] += 1
				else:
					player_res.Ores.get_or_add(ore_name, 0)
					player_res.Ores[ore_name] += 1
		area.destroy()
		collect_crystal.play_sound()


func _on_check_player_nearby_body_entered(body: Node2D) -> void:
	if body is Player:
		player_list.append(body)


func _on_check_player_nearby_body_exited(body: Node2D) -> void:
	if body is Player:
		player_list.erase(body)

func _process(delta: float) -> void:
	super(delta)



func check_if_player_has_crstal() -> void:
	for player_res:PlayerResource in GlobalGame.Players:
		if player_res.crystal_count <= 0 and !player_res.has_a_path:
			var visuel_path = VISUEL_PATH.instantiate()
			visuel_path.from_player = player_res.player
			visuel_path.to_obj = self
			get_parent().add_child(visuel_path)
			player_res.has_a_path = true

func death():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.1,0.1), 0.3)
	await(tween.finished)
	queue_free()

func get_hit():
	GSignals.CAM_shake_effect.emit(randf_range(8.0, 12.0),3)
	animation_player.play("hit")
	await (animation_player.animation_finished)
