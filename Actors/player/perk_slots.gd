extends Node
class_name PerkSlots

@export var manager: PerkManager

var has_ult := false
var ult_perk: PerkBuild = null

@export var ability: ability_slot
@export var ability_2: ability_slot
@export var ability_3: ability_slot
@export var ability_4: ability_slot


var activation_slots: Dictionary = {
	"Q": null,
	"E": null,
	"C": null,
}


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("slot_q"):
		activate_slot("Q")
	if Input.is_action_just_pressed("slot_e"):
		activate_slot("E")
	if Input.is_action_just_pressed("slot_c"):
		activate_slot("C")
	if Input.is_action_just_pressed("slot_x"):
		activate_ult()

## Called by PerkManager on ready
func init(mgr: Node) -> void:
	manager = mgr


## Returns true if all 3 activation slots are filled
func all_slots_filled() -> bool:
	for key in activation_slots:
		if activation_slots[key] == null:
			return false
	return true


## Returns true if there is at least one free activation slot
func has_free_slot() -> bool:
	return not all_slots_filled()


## Returns list of free slot keys
func get_free_slots() -> Array[String]:
	var free: Array[String] = []
	for key in activation_slots:
		if activation_slots[key] == null:
			free.append(key)
	return free


## Assigns a perk to a specific slot key (Q, E, or C)
func assign_to_slot(slot_key: String, perk: PerkBuild) -> void:
	if not activation_slots.has(slot_key):
		printerr("Invalid slot key: ", slot_key)
		return
	if activation_slots[slot_key] != null:
		printerr("Slot already filled: ", slot_key)
		return
	activation_slots[slot_key] = perk
	match slot_key:
		"Q": 
			perk.ability_slot_ref = ability_2
			perk.cooldown_started.connect(ability_2.start_cooldown)
		"E": 
			perk.ability_slot_ref = ability_3
			perk.cooldown_started.connect(ability_3.start_cooldown)
		"C": 
			perk.ability_slot_ref = ability
			perk.cooldown_started.connect(ability.start_cooldown)
		"X": 
			perk.ability_slot_ref = ability_4
			perk.cooldown_started.connect(ability_4.start_cooldown)


## Registers the selected ult perk
func register_ult(perk: PerkBuild) -> void:
	has_ult = true
	ult_perk = perk


## Activates the perk in the given slot key
func activate_slot(slot_key: String) -> void:
	var perk: PerkBuild = activation_slots.get(slot_key)
	if !is_instance_valid(perk):
		return
	if perk.is_on_cooldown():
		return
	perk.activate_perk()
	if is_instance_valid(perk.ability_slot_ref):
		perk.ability_slot_ref.show_active(perk.get_cooldown())

## Activates the perk in the given slot key
func activate_cooldowns(slot_key: String) -> void:
	var perk: PerkBuild = activation_slots.get(slot_key)
	if !is_instance_valid(perk):
		return
	
	match slot_key:
		"Q":
			ability_2.start_cooldown(perk.get_cooldown())
		"E":
			ability_3.start_cooldown(perk.get_cooldown())
		"C":
			ability.start_cooldown(perk.get_cooldown())
		"X":
			ability_4.start_cooldown(perk.get_cooldown())


## Activates the ult perk if one is assigned
func activate_ult() -> void:
	if is_instance_valid(ult_perk):
		ult_perk.activate_perk()


## Returns the perk assigned to a slot key, or null
func get_slot_perk(slot_key: String) -> PerkBuild:
	return activation_slots.get(slot_key, null)
