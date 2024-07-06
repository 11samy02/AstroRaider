extends Resource
class_name ItemConfig


enum Keys {
	Bohrer,
}

##here goes all the resource paths for each key
const KEY_PATHS = {
	Keys.Bohrer : "res://Resources/simple_bohrer_resource.tres",
}


static func get_item_resource(key : Keys) -> HoldingItem:
	return load(KEY_PATHS.get(key))

