extends Resource
class_name DialogueAmbientBark

const DialogueConditionBlock = preload("res://dialogue/conditions/condition_block.gd")
const DialogueSnippet = preload("res://dialogue/resources/dialogue_snippet.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var id: StringName
@export var label: String = ""
@export var priority: int = 0
@export var weight: float = 1.0
@export var cooldown_seconds: float = 10.0
@export var cooldown_scope: String = "actor" # actor, global, location
@export var conditions: DialogueConditionBlock
@export var snippets: Array[DialogueSnippet] = []
@export var max_uses: int = -1
@export var tags: PackedStringArray = []

func is_eligible(context: DialogueContext) -> bool:
	if conditions == null:
		return true
	return conditions.is_satisfied(context)

func get_snippet() -> DialogueSnippet:
	if snippets.is_empty():
		return null
	return snippets[randi() % snippets.size()]

