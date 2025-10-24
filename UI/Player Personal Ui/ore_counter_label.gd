@tool
extends HBoxContainer
class_name OreCounterLabel

@export var player: Player
@export var ore_id: OreTemplate.Ores
@onready var texture_rect: TextureRect = $TextureRect
@onready var count: Label = %count
@onready var cost_indikator: Label = %"cost-indikator"
var player_res: PlayerResource

const textures: Dictionary = {
	OreTemplate.Ores.Gold: "res://Sprites/Items/Ores/gold_ore.png",
	OreTemplate.Ores.Iron: "res://Sprites/Items/Ores/iron_ore.png",
	OreTemplate.Ores.Copper: "res://Sprites/Items/Ores/copper_ore.png",
}

func _ready() -> void:
	GSignals.UI_selected_blueprint.connect(_show_cost)
	GSignals.BUI_hide_resource_cost.connect(_show_cost)
	_update_texture()
	for pla_res: PlayerResource in GlobalGame.Players:
		if pla_res.player == player:
			player_res = pla_res
			break

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_texture()
	else:
		_update_label()


func _update_texture() -> void:
	var tex = load(textures[ore_id])
	if texture_rect.texture != tex:
		texture_rect.texture = tex

func _update_label() -> void:
	if player_res == null or not is_instance_valid(player_res):
		for pla_res: PlayerResource in GlobalGame.Players:
			if pla_res.player == player:
				player_res = pla_res
				break
		if player_res == null:
			visible = false
			return
	
	var key = OreTemplate.Ores.keys()[int(ore_id)]
	if key in player_res.Ores:
		count.text = str(player_res.Ores[key])
		visible = true
	else:
		count.text = "0"
		visible = true

func _show_cost(res: BluePrintResource = null) -> void:
	cost_indikator.hide()
	if !is_instance_valid(res) or res == null:
		print("Invalid or null resource, returning")
		return
	if not visible:
		return
	
	if res == null or player_res == null or player_res.Ores == null:
		return
	
	var ore_keys = OreTemplate.Ores.keys()
	if ore_id < 0 or ore_id >= ore_keys.size():
		return
	
	var key = ore_keys[int(ore_id)]
	
	if not player_res.Ores.has(key):
		return  
	
	var found := false
	for bpcr: BluePrintCostResource in res.cost:
		if bpcr.Ore == ore_id:
			print("Found matching ore_id in cost:", ore_id)
			found = true
			cost_indikator.show()
			cost_indikator.text = "-" + str(bpcr.cost)
			
			var player_has = player_res.Ores[key]
			
			if typeof(player_has) == TYPE_INT or typeof(player_has) == TYPE_FLOAT:
				if player_has >= bpcr.cost:
					cost_indikator.modulate = Color(0.0, 0.812, 0.0, 1.0)
				else:
					cost_indikator.modulate = Color(0.901, 0.0, 0.176, 1.0)
			else:
				cost_indikator.modulate = Color(0.901, 0.0, 0.176, 1.0)
			break
	if not found:
		cost_indikator.hide()
