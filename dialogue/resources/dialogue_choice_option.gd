extends Resource
class_name DialogueChoiceOption

const DialogueConditionBlock = preload("res://dialogue/conditions/condition_block.gd")
const DialogueEffect = preload("res://dialogue/effects/dialogue_effect.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var id: StringName
@export_multiline var text: String = ""
@export var template_variables: Dictionary = {}
@export var conditions: DialogueConditionBlock
@export var tags: PackedStringArray = []
@export var weight: float = 1.0
@export var next_id: StringName
@export var on_select_effects: Array[DialogueEffect] = []

func is_eligible(context: DialogueContext) -> bool:
	if conditions == null:
		return true
	return conditions.is_satisfied(context)

func render_text(context: DialogueContext, overrides: Dictionary = {}) -> String:
	var args := {}
	for key in template_variables.keys():
		args[key] = context.resolve(template_variables[key])
	for key in overrides.keys():
		args[key] = overrides[key]
	return text.format(args, "{_}")

func get_debug_state(context: DialogueContext) -> Dictionary:
	return {
		"id": id,
		"eligible": is_eligible(context),
		"next_id": next_id,
		"tags": tags,
		"weight": weight
	}

