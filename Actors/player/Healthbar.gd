extends TextureProgressBar
class_name HealthBar

@onready var timer: Timer = $Timer

@export var parent_entity: CharacterBody2D = null

var max_hp := 50
var current_hp := max_hp

var game_over := false

func _enter_tree() -> void:
	GSignals.HIT_take_Damage.connect(applay_damage)
	GSignals.HIT_take_heal.connect(applay_heal)
	GSignals.PERK_Extra_health.connect(increase_max_health)

func _ready() -> void:
	if parent_entity == null:
		queue_free()
	
	if parent_entity is Player:
		max_hp = parent_entity.stats.max_hp
	current_hp = max_hp


func _process(delta: float) -> void:
	health_control()
	update_player_health_in_res()

func update_player_health_in_res():
	for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == parent_entity:
				player_res.max_health = max_hp
				player_res.current_health = current_hp

func health_control():
	max_value = max_hp
	value = current_hp
	global_position = parent_entity.global_position + Vector2(-10,-16)
	
	if current_hp <= 0:
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == parent_entity:
				GlobalGame.Players.erase(player_res)
	if GlobalGame.Players.is_empty() and !game_over:
		game_over = true
		GameOverScreen.game_over()


func applay_damage(entity: Node2D, damage: int = 1):
	if entity == parent_entity:
		if entity is not Player:
			return
		
		if entity is Player:
			if !entity.can_take_damage:
				return
		parent_entity.get_hit_anim()
		var tween = create_tween()
		tween.parallel()
		
		timer.stop()
		tween.tween_property(self, "modulate", Color("#ffffff"), 0.05)
		tween.tween_property(self,"current_hp", current_hp - damage,0.2)
		current_hp = clampi(current_hp,0, max_hp)
		timer.start()

func applay_heal(entity: Node2D, heal_value : int):
	if entity == parent_entity:
		var tween = create_tween()
		tween.parallel()
		
		timer.stop()
		tween.tween_property(self, "modulate", Color("#ffffff"), 0.05)
		tween.tween_property(self,"current_hp", current_hp + heal_value,0.2)
		current_hp = clampi(current_hp,0, max_hp)
		if current_hp > max_hp:
			current_hp = max_hp
		timer.start()


func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#ffffff00"), 0.2)

func increase_max_health() -> void:
	var last_value = max_hp
	if parent_entity is Player:
		max_hp = parent_entity.stats.max_hp
		var perk : Perk = PerkData.load_perk_res(PerkData.Keys.Extra_Health)
		perk.level = 1
		current_hp += perk.value[0]
