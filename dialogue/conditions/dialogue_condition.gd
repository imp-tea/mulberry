extends Resource
class_name DialogueCondition

const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var id: StringName
@export var description: String = ""

func is_satisfied(context: DialogueContext) -> bool:
	return true

func get_debug_state(context: DialogueContext) -> Dictionary:
	return {
		"id": id,
		"description": description,
		"result": is_satisfied(context)
	}

