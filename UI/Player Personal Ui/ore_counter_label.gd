@tool
extends HBoxContainer
class_name OreCounterLabel

@export var player: Player
@export var ore_id: OreTemplate.Ores
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
var player_res: PlayerResource

const textures: Dictionary = {
	OreTemplate.Ores.Gold: "res://Sprites/Items/Ores/gold_ore.png",
	OreTemplate.Ores.Iron: "res://Sprites/Items/Ores/iron_ore.png",
	OreTemplate.Ores.Copper: "res://Sprites/Items/Ores/copper_ore.png",
}

func _ready() -> void:
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
		label.text = str(player_res.Ores[key])
		visible = true
	else:
		visible = false
