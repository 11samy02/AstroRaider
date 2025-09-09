extends PerkBuild

@export var added_armor := 10
@export var added_bohrer_dam := 5
@export var added_speed := 50

var time_delay : float = 0
var can_activate_perk_again : bool = false

func _process(delta: float) -> void:
	super(delta)
	_time_delay(delta)

func activate_perk() -> void:
	#stats.armor = default_armor + added_armor
	#stats.bohrer_damage = default_bohrer_dam + added_bohrer_dam
	#stats.max_speed = default_max_Speed + added_speed
	var timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	#timer.timeout.connect(_on_timer_timeout)
	timer.set_wait_time(get_value())
	timer.start()
	time_delay = 120
	await timer.timeout
	timer.queue_free()

#func reset_perk() -> void:
	#stats.armor = default_armor
	#stats.bohrer_damage = default_bohrer_dam
	#stats.max_speed = default_max_Speed

#func _exit_tree() -> void:
	#stats.armor = default_armor
	#stats.bohrer_damage = default_bohrer_dam


#func _on_timer_timeout() -> void:
	#reset_perk()

func _time_delay(delta):
	time_delay -= delta
	if time_delay <= 0:
		can_activate_perk_again = true
