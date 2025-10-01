extends Resource
class_name DialogueSnippet

const DialogueEffect = preload("res://dialogue/effects/dialogue_effect.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var id: StringName
@export_multiline var text: String = ""
@export var tags: PackedStringArray = []
@export var template_variables: Dictionary = {} # key -> property path
@export var immediate_effects: Array[DialogueEffect] = []
@export var after_display_effects: Array[DialogueEffect] = []
@export var after_input_effects: Array[DialogueEffect] = []

func is_valid() -> bool:
	return not String(id).is_empty()

func build_arguments(context: DialogueContext, overrides: Dictionary = {}) -> Dictionary:
	var args := {}
	for key in template_variables.keys():
		args[key] = context.resolve(template_variables[key])
	for key in overrides.keys():
		args[key] = overrides[key]
	return args

func render_text(context: DialogueContext, overrides: Dictionary = {}, fallback: String = "") -> String:
	var args = build_arguments(context, overrides)
	if text.is_empty():
		return fallback
	return text.format(args, "{_}")

