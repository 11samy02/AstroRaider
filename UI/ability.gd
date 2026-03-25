extends Control
class_name ability_slot

enum binding_list {
	SLOT_Q,
	SLOT_E,
	SLOT_C,
	SLOT_X,
}

@export var binding: binding_list
@export_group("Nodes")
@export var cooldown: TextureProgressBar

var _counting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	cooldown.value = 0

## Sets cooldown bar to full but frozen — called when perk is activated
func show_active(max_cooldown: float) -> void:
	cooldown.max_value = max_cooldown
	cooldown.value = max_cooldown
	_counting = false

## Starts counting down — called when shield is destroyed
func start_cooldown(max_cooldown: float) -> void:
	cooldown.max_value = max_cooldown
	cooldown.value = max_cooldown
	_counting = true

func _physics_process(delta: float) -> void:
	if not _counting or cooldown.value <= 0:
		cooldown.value = max(cooldown.value - 0.0, 0.0)
		return
	cooldown.value -= delta
