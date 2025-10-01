extends Resource
class_name DialogueConditionBlock

const DialogueCondition = preload("res://dialogue/conditions/dialogue_condition.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var require_all: Array[DialogueCondition] = []
@export var require_any: Array[DialogueCondition] = []
@export var require_none: Array[DialogueCondition] = []

func is_satisfied(context: DialogueContext) -> bool:
	if require_all.any(func(cond): return cond != null and not cond.is_satisfied(context)):
		return false
	if require_any.size() > 0 and not require_any.any(func(cond): return cond != null and cond.is_satisfied(context)):
		return false
	if require_none.any(func(cond): return cond != null and cond.is_satisfied(context)):
		return false
	return true

func get_debug_state(context: DialogueContext) -> Dictionary:
	return {
		"all": _evaluate_list(require_all, context),
		"any": _evaluate_list(require_any, context),
		"none": _evaluate_list(require_none, context)
	}

func _evaluate_list(items: Array, context: DialogueContext) -> Array:
	var debug := []
	for cond in items:
		if cond != null:
			debug.append(cond.get_debug_state(context))
	return debug

