extends TextureProgressBar
class_name HealthBar

@onready var timer: Timer = $Timer

var parent_entity: Node2D = null

var max_hp := 100
var current_hp := max_hp

func _enter_tree() -> void:
	GSignals.PLA_take_damage.connect(applay_damage)

func _ready() -> void:
	if parent_entity == null:
		queue_free()


func _process(delta: float) -> void:
	max_value = max_hp
	value = current_hp
	global_position = parent_entity.global_position + Vector2(-10,-16)
	
	if current_hp <= 0:
		get_tree().change_scene_to_file("res://Titel/start_loading.tscn")


func applay_damage(entity: Node2D, damage: int = 1):
	if entity == parent_entity:
		var tween = create_tween()
		tween.parallel()
		
		timer.stop()
		tween.tween_property(self, "modulate", Color("#ffffff"), 0.05)
		tween.tween_property(self,"current_hp", current_hp - damage,0.2)
		current_hp = clampi(current_hp,0, max_hp)
		timer.start()



func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#ffffff00"), 0.2)
