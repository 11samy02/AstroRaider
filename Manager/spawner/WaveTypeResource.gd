extends Resource
class_name WaveTypeResource

enum WaveTypeEnum {
	Pause,
}


@export var WaveType : WaveTypeEnum = WaveTypeEnum.Pause
@export var WaveStart : int = 1
@export var repeatable : bool = false
