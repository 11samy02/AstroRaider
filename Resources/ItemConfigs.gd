extends Resource
class_name ItemConfig

enum Type {
	Ranged_Weapon,
}

enum Keys {
	Photon_Gun,
}

##here goes all the resource paths for each key
const KEY_PATHS = {
	Keys.Photon_Gun: "res://Resources/Holding_items/Photon_Gun.tres",
}


static func get_item_resource(key : Keys) -> HoldingItem:
	return load(KEY_PATHS.get(key))


const KEY_PATHS_SZENE = {
	Keys.Photon_Gun: "res://Projectiles/Photon_gun_projectile.tscn",
}

static func get_item_scene(key : Keys) -> PackedScene:
	return load(KEY_PATHS_SZENE.get(key))
