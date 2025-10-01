extends Resource
class_name DialogueAmbientBarkSet

const DialogueAmbientBark = preload("res://dialogue/resources/ambient_bark.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var set_id: StringName
@export var label: String = ""
@export var default_cooldown: float = 15.0
@export var barks: Array[DialogueAmbientBark] = []

func eligible_barks(context: DialogueContext) -> Array[DialogueAmbientBark]:
	var options: Array[DialogueAmbientBark] = []
	for bark in barks:
		if bark != null and bark.is_eligible(context):
			options.append(bark)
	return options

