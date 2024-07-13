extends Resource
class_name Perk



enum Active_type_keys {
	Start,
	OneTime,
	TimeDelay,
	Always,
}

enum Type_keys {
	Movement,
	Defens,
	Offens,
	Team,
	Mining,
}

@export var image: Texture2D
@export var Key: PerkData.Keys
@export var perk_name := ""
@export_multiline var description := ""
@export var type : Type_keys
@export var active_type : Active_type_keys
