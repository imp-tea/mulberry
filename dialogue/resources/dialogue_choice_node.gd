extends "res://dialogue/resources/dialogue_node.gd"
class_name DialogueChoiceNode

const DialogueSnippet = preload("res://dialogue/resources/dialogue_snippet.gd")
const DialogueChoiceOption = preload("res://dialogue/resources/dialogue_choice_option.gd")

@export var prompt: DialogueSnippet
@export var options: Array[DialogueChoiceOption] = []
@export var auto_choose_single: bool = true
@export var allow_skip: bool = false

func get_next_candidates(context: DialogueContext) -> Array[StringName]:
	var result: Array[StringName] = []
	for option in options:
		if option != null and option.is_eligible(context) and option.next_id != StringName():
			result.append(option.next_id)
	return result

func eligible_options(context: DialogueContext) -> Array[DialogueChoiceOption]:
	var result: Array[DialogueChoiceOption] = []
	for option in options:
		if option != null and option.is_eligible(context):
			result.append(option)
	return result

