extends Resource
class_name DialogueNode

const DialogueConditionBlock = preload("res://dialogue/conditions/condition_block.gd")
const DialogueEffect = preload("res://dialogue/effects/dialogue_effect.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var id: StringName
@export var label: String = ""
@export var conditions: DialogueConditionBlock
@export var tags: PackedStringArray = []
@export var priority: int = 0
@export var weight: float = 1.0
@export var cooldown_seconds: float = 0.0
@export var allow_reentry: bool = true
@export var on_enter_effects: Array[DialogueEffect] = []
@export var on_exit_effects: Array[DialogueEffect] = []

func is_eligible(context: DialogueContext) -> bool:
	if conditions == null:
		return true
	return conditions.is_satisfied(context)

func get_next_candidates(_context: DialogueContext) -> Array[StringName]:
	return []

func get_debug_metadata(context: DialogueContext) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"eligible": is_eligible(context),
		"tags": tags,
		"priority": priority,
		"weight": weight
	}

