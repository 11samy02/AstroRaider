extends MarginContainer
class_name BossHealthBar

@export var Boss: Node2D
@export_range(0, 1, 0.01) var diff_ratio_procentage := 0.12
@export_range(0, 1, 0.01) var glow_threshold := 0.25
@export var boss_stats: BossStats
@onready var bar: TextureProgressBar = $real_bar
@onready var chip_bar: TextureProgressBar = $chip_bar

var glow_tween: Tween
var glow_active := false
var alive_modulate := Color(1, 1, 1, 1)
var dead_modulate := Color(0.20, 0.20, 0.20, 1)
var death_tween: Tween
var death_played := false
var vanish_tween: Tween
var vanish_done := false
var _vanish_origin := Vector2.ZERO


## Initialisiert Material/Max-Werte und setzt den Startzustand (Glow/Dead-Bar).
func _ready() -> void:
	if bar.material:
		bar.material = bar.material.duplicate()
		bar.material.resource_local_to_scene = true
		bar.material.set_shader_parameter("glow_intensity", 0.0)
		bar.material.set_shader_parameter("crit_intensity", 0.0)
		bar.material.set_shader_parameter("crit_active", false)

	bar.max_value = boss_stats.Max_HP
	chip_bar.max_value = boss_stats.Max_HP
	bar.value = boss_stats.current_hp
	chip_bar.value = boss_stats.current_hp

	update_glow_state()


## Test-Input und regelmäßige Aktualisierung des Glow-Zustands.
func _process(_delta: float) -> void:
	update_glow_state()


## Aktualisiert visuelle Zustände: Puls-Glow unter Schwelle, epischer Dead-State bei 0 HP.
func update_glow_state() -> void:
	if not bar.material:
		return

	if boss_stats.Max_HP <= 0 or boss_stats.current_hp <= 0.0:
		stop_glow_pulse()
		bar.material.set_shader_parameter("glow_intensity", 0.0)
		bar.material.set_shader_parameter("crit_active", false)
		_play_death_sequence()
		return

	_cancel_death_sequence()
	_set_alive_state()

	var hp_ratio: float = float(boss_stats.current_hp) / float(boss_stats.Max_HP)
	if hp_ratio < glow_threshold:
		if not glow_active:
			start_glow_pulse()
	else:
		if glow_active:
			stop_glow_pulse()
		else:
			bar.material.set_shader_parameter("glow_intensity", 0.0)


## Wendet Schaden an, animiert Chip-Bar, Feedback und Zustände.
func get_damage(amount: float, is_crit: bool = false) -> void:
	var old_hp: float = boss_stats.current_hp
	var new_hp: float = clamp(old_hp - amount, 0.0, float(boss_stats.Max_HP))
	boss_stats.current_hp = new_hp

	bar.value = round(new_hp)

	var diff_ratio := 0.0
	if boss_stats.Max_HP > 0:
		diff_ratio = (old_hp - new_hp) / float(boss_stats.Max_HP)

	var dur = lerp(0.18, 0.42, clamp(diff_ratio * 1.4, 0.0, 1.0))
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUINT)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(chip_bar, "value", round(new_hp), dur)

	if new_hp > 0.0:
		hit_flash()
		if diff_ratio > diff_ratio_procentage:
			micro_shake()
		if is_crit:
			crit_pulse()

	update_glow_state()


## Heilt HP, animiert reale Bar und aktualisiert Zustände.
func heal(amount: float) -> void:
	var old_hp: float = boss_stats.current_hp
	var new_hp: float = clamp(old_hp + amount, 0.0, float(boss_stats.Max_HP))
	boss_stats.current_hp = new_hp

	chip_bar.value = round(new_hp)

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(bar, "value", round(new_hp), 0.28)

	update_glow_state()


## Kurzer Treffer-Flash auf der Hauptleiste.
func hit_flash() -> void:
	var t := create_tween()
	t.tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.04)
	t.tween_property(bar, "modulate", Color(1, 1, 1, 0.96), 0.10)


## Minimaler Horizontal-Ruck für die Leiste selbst (kein globales Movement).
func micro_shake(intensity: float = 3.0, dur: float = 0.15) -> void:
	var start := position
	var t := create_tween()
	t.tween_property(self, "position", start + Vector2(-intensity, 0), dur * 0.25)
	t.tween_property(self, "position", start + Vector2(intensity, 0), dur * 0.50)
	t.tween_property(self, "position", start, dur * 0.25)


## Kritischer Hit-Puls im Material (nur wenn lebendig).
func crit_pulse() -> void:
	if not bar.material or boss_stats.current_hp <= 0.0:
		return
	bar.material.set_shader_parameter("crit_active", true)
	bar.material.set_shader_parameter("crit_intensity", 0.0)
	var t := create_tween()
	t.tween_property(bar.material, "shader_parameter/crit_intensity", 1.0, 0.08)
	t.tween_property(bar.material, "shader_parameter/crit_intensity", 0.0, 0.16)
	t.tween_callback(Callable(self, "_end_crit"))


## Beendet den Crit-Status im Shader.
func _end_crit() -> void:
	if bar.material:
		bar.material.set_shader_parameter("crit_active", false)


## Startet Herzschlag-Glow (Doppel-Schlag) mit HP-abhängiger Geschwindigkeit/Intensität.
func start_glow_pulse() -> void:
	stop_glow_pulse()
	glow_active = true
	if not bar.material:
		return

	var hp_ratio: float = 0.0
	if boss_stats.Max_HP > 0.0:
		hp_ratio = float(boss_stats.current_hp) / float(boss_stats.Max_HP)

	var zone: float = max(glow_threshold, 0.001)
	var t_ratio: float = clamp(1.0 - (hp_ratio / zone), 0.0, 1.0)
	var bpm: float = lerp(70.0, 160.0, t_ratio)
	var cycle: float = 60.0 / bpm

	var base_up1: float = 0.08
	var base_down1: float = 0.12
	var base_gap: float = 0.06
	var base_up2: float = 0.07
	var base_down2: float = 0.12
	var base_sum: float = base_up1 + base_down1 + base_gap + base_up2 + base_down2
	var scale: float = cycle / max(base_sum, 0.0001)

	var up1: float = base_up1 * scale
	var down1: float = base_down1 * scale
	var gap: float = base_gap * scale
	var up2: float = base_up2 * scale
	var down2: float = base_down2 * scale

	var min_i: float = 0.18
	var max_i: float = 0.95
	var base_i: float = lerp(0.25, 0.35, t_ratio)
	var peak1_i: float = lerp(0.75, 0.95, t_ratio)
	var peak2_i: float = lerp(0.62, 0.82, t_ratio)
	var low_i: float = lerp(0.22, 0.30, t_ratio)

	bar.material.set_shader_parameter("glow_intensity", clamp(base_i, min_i, max_i))

	glow_tween = create_tween()
	var tp1 = glow_tween.tween_property(bar.material, "shader_parameter/glow_intensity", clamp(peak1_i, min_i, max_i), up1)
	tp1.set_trans(Tween.TRANS_QUINT); tp1.set_ease(Tween.EASE_OUT)

	var tp2 = glow_tween.tween_property(bar.material, "shader_parameter/glow_intensity", clamp(low_i, min_i, max_i), down1)
	tp2.set_trans(Tween.TRANS_SINE); tp2.set_ease(Tween.EASE_IN)

	glow_tween.tween_interval(gap)

	var tp3 = glow_tween.tween_property(bar.material, "shader_parameter/glow_intensity", clamp(peak2_i, min_i, max_i), up2)
	tp3.set_trans(Tween.TRANS_QUINT); tp3.set_ease(Tween.EASE_OUT)

	var tp4 = glow_tween.tween_property(bar.material, "shader_parameter/glow_intensity", clamp(base_i, min_i, max_i), down2)
	tp4.set_trans(Tween.TRANS_SINE); tp4.set_ease(Tween.EASE_IN)

	glow_tween.tween_callback(Callable(self, "start_glow_pulse"))


## Stoppt Glow-Tween und setzt die Intensität zurück.
func stop_glow_pulse() -> void:
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
	glow_tween = null
	glow_active = false
	if bar.material:
		bar.material.set_shader_parameter("glow_intensity", 0.0)


## Epische Dead-Sequenz (ohne Bewegung): Weiß-Flash → Blutrot → Flicker → Ausglühen → Verkohlt.
func _play_death_sequence() -> void:
	if death_played:
		return
	death_played = true

	stop_glow_pulse()
	if bar.material:
		bar.material.set_shader_parameter("crit_active", false)
		bar.material.set_shader_parameter("glow_intensity", 0.0)

	if death_tween and death_tween.is_valid():
		death_tween.kill()

	death_tween = create_tween()
	death_tween.set_trans(Tween.TRANS_SINE)
	death_tween.set_ease(Tween.EASE_OUT)

	var flash_up := death_tween.tween_property(bar, "modulate", Color(1, 1, 1, 1), 0.05)
	flash_up.set_trans(Tween.TRANS_QUINT); flash_up.set_ease(Tween.EASE_OUT)

	var crimson := Color(0.85, 0.15, 0.15, 1.0)
	var to_crimson := death_tween.tween_property(bar, "modulate", crimson, 0.10)
	to_crimson.set_trans(Tween.TRANS_QUAD); to_crimson.set_ease(Tween.EASE_OUT)

	if bar.material:
		var flick := create_tween()
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.90, 0.06)
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.15, 0.07)
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.70, 0.05)
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.10, 0.08)
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.50, 0.04)
		flick.tween_property(bar.material, "shader_parameter/glow_intensity", 0.00, 0.16)

	var chip_flick := create_tween()
	chip_flick.tween_property(chip_bar, "modulate", crimson.lightened(0.15), 0.06)
	chip_flick.tween_property(chip_bar, "modulate", crimson.darkened(0.25), 0.07)
	chip_flick.tween_property(chip_bar, "modulate", crimson, 0.05)
	chip_flick.tween_property(chip_bar, "modulate", crimson.darkened(0.35), 0.10)

	var to_dead_main := death_tween.tween_property(bar, "modulate", dead_modulate, 0.30)
	to_dead_main.set_trans(Tween.TRANS_SINE); to_dead_main.set_ease(Tween.EASE_IN)

	var to_dead_chip := death_tween.tween_property(chip_bar, "modulate", dead_modulate.darkened(0.05), 0.30)
	to_dead_chip.set_trans(Tween.TRANS_SINE); to_dead_chip.set_ease(Tween.EASE_IN)

	death_tween.tween_callback(func ():
		if bar.material:
			bar.material.set_shader_parameter("glow_intensity", 0.0)
	)
	death_tween.tween_callback(Callable(self, "_vanish_after_death"))


## Bricht eine laufende Death-Animation ab und stellt den normalen Look wieder her.
func _cancel_death_sequence() -> void:
	if death_tween and death_tween.is_valid():
		death_tween.kill()
	death_tween = null
	death_played = false
	_set_alive_state()
	if bar.material:
		bar.material.set_shader_parameter("glow_intensity", 0.0)
	_cancel_vanish()


## Setzt dunkleren Look für die „Dead Bar“ (Fallback).
func _set_dead_state() -> void:
	bar.modulate = dead_modulate
	chip_bar.modulate = dead_modulate


## Setzt normalen Look für lebendige Zustände.
func _set_alive_state() -> void:
	bar.modulate = alive_modulate
	chip_bar.modulate = alive_modulate


## Lässt die gesamte Healthbar stilvoll verschwinden (nach der Dead-Animation).
func _vanish_after_death() -> void:
	if vanish_done:
		return
	vanish_done = true
	_vanish_origin = position
	pivot_offset = size * 0.5
	if vanish_tween and vanish_tween.is_valid():
		vanish_tween.kill()
	vanish_tween = create_tween()
	vanish_tween.set_trans(Tween.TRANS_QUART)
	vanish_tween.set_ease(Tween.EASE_IN_OUT)
	vanish_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.10)
	var shrink_time := 0.22
	vanish_tween.parallel().tween_property(self, "scale", Vector2(0.82, 0.82), shrink_time)
	vanish_tween.parallel().tween_property(self, "modulate:a", 0.0, shrink_time)
	vanish_tween.parallel().tween_property(self, "position:y", _vanish_origin.y - 8.0, shrink_time)
	vanish_tween.tween_callback(Callable(self, "_after_vanish"))


## Wird nach dem Verschwinden aufgerufen – setzt Werte zurück und blendet aus.
func _after_vanish() -> void:
	hide()
	modulate.a = 1.0
	scale = Vector2.ONE
	position = _vanish_origin


## Hebt eine laufende Vanish-Animation auf (z. B. bei Revive).
func _cancel_vanish() -> void:
	if vanish_tween and vanish_tween.is_valid():
		vanish_tween.kill()
	vanish_tween = null
	vanish_done = false
	show()
	modulate.a = 1.0
	scale = Vector2.ONE
	position = _vanish_origin
