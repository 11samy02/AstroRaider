extends EnemyBaseTemplate
class_name Bat

@onready var state_machine: EnemyStateMachine = $Scripts/StateMachine
@onready var shader_effects: EnemyShaderEffects = $Scripts/ShaderEffects

static var kill_count: int = 0


func _ready() -> void:
	super()
	state_machine.enemy = self
	state_machine.wander_time = $Timer/wander_time
	state_machine.follow_time = $Timer/follow_time
	shader_effects.enemy = self
	$Timer/wander_time.timeout.connect(state_machine.on_wander_timeout)


## Runs health check, shader effects and state machine each physics frame
func _physics_process(_delta: float) -> void:
	check_health()
	shader_effects.run()
	state_machine.run()


## Increments kill count and triggers base death logic
func death() -> void:
	kill_count += 1
	super()


## Applies damage and triggers hit animation
func applay_damage(entity: CharacterBody2D, damage: int = 1, crit_chance: float = 0.00) -> void:
	super(entity, damage, crit_chance)
	if entity == self:
		get_hit_anim()
