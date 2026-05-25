extends Resource
class_name TaskResource

enum TaskKind {
	TUTORIAL,
	TASK,
	CHALLENGE,
	DAILY_CHALLENGE,
	BOSS_CHALLENGE,
}

const DEFAULT_TITLES := {
	TaskKind.TUTORIAL: "DAEMON DIRECTIVE",
	TaskKind.TASK: "TASK",
	TaskKind.CHALLENGE: "CHALLENGE",
	TaskKind.DAILY_CHALLENGE: "DAILY CHALLENGE",
	TaskKind.BOSS_CHALLENGE: "BOSS CHALLENGE",
}

const KIND_ACCENTS := {
	TaskKind.TUTORIAL: Color(0.9, 0.18, 0.18, 1.0),
	TaskKind.TASK: Color(0.42, 0.72, 1.0, 1.0),
	TaskKind.CHALLENGE: Color(1.0, 0.72, 0.22, 1.0),
	TaskKind.DAILY_CHALLENGE: Color(0.50, 0.95, 0.68, 1.0),
	TaskKind.BOSS_CHALLENGE: Color(0.98, 0.28, 0.48, 1.0),
}

@export_category("Identity")
@export var key := ""
@export var task_kind: TaskKind = TaskKind.TASK

@export_category("Display")
@export var title_override := ""
@export_multiline var task_text := ""
@export var title_color := Color(0.67, 0.77, 0.88, 1.0)
@export var task_color := Color(0.98, 0.92, 0.74, 1.0)

@export_category("Reward")
@export var challenge_exp := 0


static func get_default_title_for_kind(kind: int) -> String:
	return str(DEFAULT_TITLES.get(kind, DEFAULT_TITLES[TaskKind.TASK]))


static func get_accent_color_for_kind(kind: int) -> Color:
	return KIND_ACCENTS.get(kind, KIND_ACCENTS[TaskKind.TASK])


func get_title_text() -> String:
	if title_override.strip_edges() != "":
		return title_override
	return get_default_title_for_kind(task_kind)


func get_display_text(values: Dictionary = {}) -> String:
	var result := task_text

	for value_key in values.keys():
		result = result.replace("{%s}" % str(value_key), str(values[value_key]))

	return result


func get_reward_exp() -> int:
	if task_kind == TaskKind.TUTORIAL:
		return 0
	return max(challenge_exp, 0)
