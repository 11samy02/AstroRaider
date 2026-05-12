extends Resource
class_name BossPhaseData

## Optional display name for this phase in the editor.
@export var phase_name: String = ""

## Health threshold that activates this phase. 1.0 means full health, 0.5 means 50% health or lower.
@export_range(0.0, 1.0, 0.01) var health_ratio: float = 1.0
