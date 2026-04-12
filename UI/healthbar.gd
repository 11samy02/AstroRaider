extends TextureProgressBar

const HEAL_PARTICLE := preload("res://Particles/heal_particle.tscn")

@export var game_ui: GameUi
@export var chip_bar: TextureProgressBar
@export var health_label: Label
@export_range(0, 1, 0.01) var diff_ratio_percentage := 0.08
@export_range(0, 1, 0.01) var glow_threshold := 0.25

@onready var bar: TextureProgressBar = self

var player_res: PlayerResource = null
var game_over := false
var glow_tween: Tween
var glow_active := false
var death_played := false

func _enter_tree() -> void:
	GSignals.HIT_take_Damage.connect(applay_damage)
	GSignals.HIT_take_heal.connect(applay_heal)
	GSignals.PERK_Extra_health.connect(increase_max_health)

func _ready() -> void:
	await game_ui.ready
	call_deferred("setup_player_res")

func _process(_delta: float) -> void:
	if player_res == null:
		setup_player_res()
		return
	_sync_max_health()
	_check_game_over()
	_set_health_label_text()
	update_glow_state()

## Resolves the player resource from the game UI player reference
func setup_player_res() -> void:
	if game_ui == null or game_ui.player == null or GlobalGame.Players.is_empty():
		return
	for p_res: PlayerResource in GlobalGame.Players:
		if p_res.player == game_ui.player:
			player_res = p_res
			max_value = player_res.max_health
			value = player_res.current_health
			if is_instance_valid(chip_bar):
				chip_bar.max_value = player_res.max_health
				chip_bar.value = player_res.current_health
			return

## Syncs max health each frame
func _sync_max_health() -> void:
	if player_res == null or game_ui.player == null:
		return
	player_res.max_health = game_ui.player.stats.get_max_hp_total()
	player_res.current_health = clampi(player_res.current_health, 0, player_res.max_health)
	max_value = player_res.max_health
	value = player_res.current_health
	if is_instance_valid(chip_bar):
		chip_bar.max_value = player_res.max_health

## Checks for game over condition
func _check_game_over() -> void:
	if player_res == null:
		return
	if player_res.current_health <= 0:
		if GlobalGame.Players.has(player_res):
			GlobalGame.Players.erase(player_res)
		if GlobalGame.Players.is_empty() and !game_over:
			game_over = true
			GameOverScreen.game_over()

## Applies damage with chip effect and feedback
func applay_damage(entity: Node2D, damage: int = 1, crit: float = 1.00) -> void:
	if player_res == null or entity != game_ui.player:
		return
	if entity is not Player or !entity.can_take_damage:
		return
	game_ui.player.get_hit_anim()
	var old_hp := player_res.current_health
	var new_hp := clampi(old_hp - damage, 0, player_res.max_health)
	player_res.current_health = new_hp
	value = new_hp
	var diff_ratio := float(old_hp - new_hp) / float(player_res.max_health)
	_animate_chip(new_hp, diff_ratio)
	hit_flash()
	if diff_ratio > diff_ratio_percentage:
		micro_shake()
	if crit > 0.0:
		crit_pulse()
	update_glow_state()

## Animates the chip bar with delay
func _animate_chip(target: int, diff_ratio: float) -> void:
	if !is_instance_valid(chip_bar):
		return
	chip_bar.value = player_res.current_health + (player_res.max_health * diff_ratio)
	var dur = lerp(0.18, 0.42, clamp(diff_ratio * 1.4, 0.0, 1.0))
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUINT)
	t.set_ease(Tween.EASE_OUT)
	t.tween_interval(0.15)
	t.tween_property(chip_bar, "value", float(target), dur)

## Applies healing with animation
func applay_heal(entity: Node2D, heal_value: int) -> void:
	if player_res == null or entity != game_ui.player:
		return
	var particle := HEAL_PARTICLE.instantiate()
	entity.add_child(particle)
	var new_hp := clampi(player_res.current_health + heal_value, 0, player_res.max_health)
	player_res.current_health = new_hp
	if is_instance_valid(chip_bar):
		chip_bar.value = float(new_hp)
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "value", float(new_hp), 0.25)
	update_glow_state()

## Updates max health when Extra Health perk is selected
func increase_max_health() -> void:
	if player_res == null or player_res.player is not Player:
		return
	var new_max := player_res.player.stats.get_max_hp_total()
	var diff := new_max - player_res.max_health
	player_res.max_health = new_max
	player_res.current_health = clampi(player_res.current_health + diff, 0, player_res.max_health)
	max_value = player_res.max_health
	if is_instance_valid(chip_bar):
		chip_bar.max_value = player_res.max_health

## Short hit flash on the bar
func hit_flash() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.04)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.10)

## Small horizontal shake on big hits
func micro_shake(intensity: float = 3.0, dur: float = 0.15) -> void:
	var start := position
	var t := create_tween()
	t.tween_property(self, "position", start + Vector2(-intensity, 0), dur * 0.25)
	t.tween_property(self, "position", start + Vector2(intensity, 0), dur * 0.50)
	t.tween_property(self, "position", start, dur * 0.25)

## Crit pulse effect — only if material supports it
func crit_pulse() -> void:
	if not material:
		return
	material.set_shader_parameter("crit_active", true)
	material.set_shader_parameter("crit_intensity", 0.0)
	var t := create_tween()
	t.tween_property(material, "shader_parameter/crit_intensity", 1.0, 0.08)
	t.tween_property(material, "shader_parameter/crit_intensity", 0.0, 0.16)
	t.tween_callback(func(): material.set_shader_parameter("crit_active", false))

## Updates glow state based on current HP ratio
func update_glow_state() -> void:
	if player_res == null or player_res.max_health <= 0:
		return
	var hp_ratio := float(player_res.current_health) / float(player_res.max_health)
	if hp_ratio < glow_threshold:
		if not glow_active:
			start_glow_pulse()
	else:
		if glow_active:
			stop_glow_pulse()

## Heartbeat glow pulse at low HP
func start_glow_pulse() -> void:
	stop_glow_pulse()
	glow_active = true
	if not material:
		return
	var hp_ratio := float(player_res.current_health) / float(player_res.max_health)
	var t_ratio = clamp(1.0 - (hp_ratio / max(glow_threshold, 0.001)), 0.0, 1.0)
	var bpm = lerp(70.0, 160.0, t_ratio)
	var cycle = 60.0 / bpm
	var base_sum := 0.08 + 0.12 + 0.06 + 0.07 + 0.12
	var scale = cycle / max(base_sum, 0.0001)
	var peak1 = lerp(0.75, 0.95, t_ratio)
	var peak2 = lerp(0.62, 0.82, t_ratio)
	var base_i = lerp(0.25, 0.35, t_ratio)
	var low_i = lerp(0.22, 0.30, t_ratio)
	material.set_shader_parameter("glow_intensity", base_i)
	glow_tween = create_tween()
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", peak1, 0.08 * scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", low_i, 0.12 * scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	glow_tween.tween_interval(0.06 * scale)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", peak2, 0.07 * scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", base_i, 0.12 * scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	glow_tween.tween_callback(Callable(self, "start_glow_pulse"))

## Stops the glow pulse
func stop_glow_pulse() -> void:
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
	glow_tween = null
	glow_active = false
	if material:
		material.set_shader_parameter("glow_intensity", 0.0)

## Sets the label text to the Current Health
func _set_health_label_text() -> void:
	health_label.set_text(str(roundi(value)) + " / " + str(roundi(max_value)))
	
