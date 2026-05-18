extends Node

enum Keys {
	Speed_It_Up,
	Construction_Expert,
	Coin_Master,
	Vampire_Bite,
	Each_Round_Heal,
	Resilience,
	Barrier_Shield,
	Aim_Bot,
	Extra_Health,
	Impulse_Drive,
	Piercing_Shot,
	Stun_Grenade,
	Energy_Overload,
	Emergency_Heal,
	Anti_Mine_Detection,
	Resource_Sharing,
	Group_Momentum,
	Rallying_Cry,
	Protective_Aura,
	Critical_Edge,
	Power_Shot,
	Temporal_Collapse,
	Blood_Claws,
	Sentinel_Drone,
	Magnetic_Pull,
}

const Keys_scene = {
	Keys.Speed_It_Up:  "res://scenes/perks/perk_build/Perk_speed_it_up.tscn",
	Keys.Construction_Expert: "res://scenes/perks/perk_build/Perk_construction_expert.tscn",
	Keys.Coin_Master: "res://scenes/perks/perk_build/Perk_CoinMaster.tscn",
	Keys.Vampire_Bite: "res://scenes/perks/perk_build/Perk_Vampire_Bite.tscn",
	Keys.Each_Round_Heal: "res://scenes/perks/perk_build/Perk_Each_Round_Heal.tscn",
	Keys.Resilience: "res://scenes/perks/perk_build/Perk_Resilience.tscn",
	Keys.Barrier_Shield: "res://scenes/perks/perk_build/Perk_Barrier_Shield.tscn",
	Keys.Aim_Bot: "res://scenes/perks/perk_build/Perk_Aim_Bot.tscn",
	Keys.Extra_Health: "res://scenes/perks/perk_build/Perk_Extra_Health.tscn",
	Keys.Impulse_Drive: "res://scenes/perks/perk_build/Perk_Impulse_Drive.tscn",
	Keys.Piercing_Shot: "res://scenes/perks/perk_build/Perk_Piercing_Shot.tscn",
	Keys.Stun_Grenade: "res://scenes/perks/perk_build/Perk_Stun_Grenade.tscn",
	Keys.Energy_Overload: "res://scenes/perks/perk_build/Perk_Energy_Overload.tscn",
	Keys.Emergency_Heal: "res://scenes/perks/perk_build/Perk_Emergency_Heal.tscn",
	Keys.Anti_Mine_Detection: "res://scenes/perks/perk_build/Perk_Anti_Mine_Detection.tscn",
	Keys.Resource_Sharing: "res://scenes/perks/perk_build/Perk_Resource_Sharing.tscn",
	Keys.Group_Momentum: "",
	Keys.Rallying_Cry: "",
	Keys.Protective_Aura: "",
	Keys.Critical_Edge: "res://scenes/perks/perk_build/Perk_Critical_Edge.tscn",
	Keys.Power_Shot: "res://scenes/perks/perk_build/Perk_Power_Shot.tscn",
	Keys.Temporal_Collapse: "res://scenes/perks/perk_build/perk_temporal_collapse.tscn",
	Keys.Blood_Claws: "res://scenes/perks/perk_build/perk_blood_claws.tscn",
	Keys.Sentinel_Drone: "res://scenes/perks/perk_build/perk_sentinel_drone.tscn",
	Keys.Magnetic_Pull: "res://scenes/perks/perk_build/Perk_Magnetic_Pull.tscn",
}

const Keys_res = {
	Keys.Speed_It_Up: "res://resources/perks/Perk_Speed_it_up.tres",
	Keys.Construction_Expert: "res://resources/perks/Perk_Construction_expert.tres",
	Keys.Coin_Master: "res://resources/perks/Perk_Coin_Master.tres",
	Keys.Vampire_Bite: "res://resources/perks/Perk_Vampire_Bite.tres",
	Keys.Each_Round_Heal: "res://resources/perks/Perk_Each_Round_Heal.tres",
	Keys.Resilience: "res://resources/perks/Perk_Resilience.tres",
	Keys.Barrier_Shield: "res://resources/perks/Perk_Barrier_Shield.tres",
	Keys.Aim_Bot: "res://resources/perks/Perk_Aim_Bot.tres",
	Keys.Extra_Health: "res://resources/perks/Perk_Extra_Health.tres",
	Keys.Impulse_Drive: "res://resources/perks/Perk_Impulse_drive.tres",
	Keys.Piercing_Shot: "res://resources/perks/Perk_Piercing_Shot.tres",
	Keys.Stun_Grenade: "res://resources/perks/Perk_Stun_Grenade.tres",
	Keys.Energy_Overload: "res://resources/perks/Perk_Energy_Overload.tres",
	Keys.Emergency_Heal: "res://resources/perks/Perk_Emergency_Heal.tres",
	Keys.Anti_Mine_Detection: "res://resources/perks/Perk_Anti_Mine_Detection.tres",
	Keys.Resource_Sharing: "res://resources/perks/Perk_Resource_Sharing.tres",
	Keys.Group_Momentum: "",
	Keys.Rallying_Cry: "",
	Keys.Protective_Aura: "",
	Keys.Critical_Edge: "res://resources/perks/Perk_Critical_Edge.tres",
	Keys.Power_Shot: "res://resources/perks/Perk_Power_Shot.tres",
	Keys.Temporal_Collapse: "res://resources/perks/Perk_Temporal_Collapse.tres",
	Keys.Blood_Claws: "res://resources/perks/Perk_Blood_Claws.tres",
	Keys.Sentinel_Drone: "res://resources/perks/Perk_sentinel_drone.tres",
	Keys.Magnetic_Pull: "res://resources/perks/Perk_Magnetic_Pull.tres",
}

static var _scene_cache := {}
static var _res_cache := {}

static func load_perk_scene(key: Keys) -> PackedScene:
	var path = Keys_scene.get(key)
	if path == null or path == "":
		return null
	if _scene_cache.has(key):
		return _scene_cache[key].duplicate()
	var scene: PackedScene = load(path)
	_scene_cache[key] = scene
	return scene.duplicate()

static func load_perk_res(key: Keys) -> Perk:
	var path = Keys_res.get(key)
	if path == null or path == "":
		return null
	if _res_cache.has(key):
		return _res_cache[key].duplicate()
	var res: Perk = load(path)
	_res_cache[key] = res
	return res.duplicate()
