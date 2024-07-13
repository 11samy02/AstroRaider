extends Resource
class_name Perk


@export var Key: PerkData.Keys
@export var perk_name := ""
@export_multiline var description := ""
@export_enum("Movement", "Defens", "Offens", "Team", "Mining") var type
@export_enum("Always", "One Time", "Time Delay") var active_type 
