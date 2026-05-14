extends Resource
class_name PlayerCharacterBuild

## Display name of this saved player build.
@export var build_name := ""
## Suit selected by this build.
@export var selected_suit: SuitData.SuitKeys = SuitData.SuitKeys.Trailblazer
## Perks already unlocked by this saved build.
@export var unlocked_perks: Array[Perk] = []
