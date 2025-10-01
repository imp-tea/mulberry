extends "res://dialogue/resources/dialogue_node.gd"
class_name DialogueJumpNode

@export var target_id: StringName

func get_next_candidates(_context: DialogueContext) -> Array[StringName]:
	if target_id == StringName():
		return []
	return [target_id]

