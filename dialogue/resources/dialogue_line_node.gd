extends "res://dialogue/resources/dialogue_node.gd"
class_name DialogueLineNode

const DialogueSnippet = preload("res://dialogue/resources/dialogue_snippet.gd")

@export var speaker_id: StringName
@export var address_to: StringName
@export var snippets: Array[DialogueSnippet] = []
@export var next_id: StringName
@export var auto_advance: bool = false
@export var auto_advance_delay: float = 0.0
@export var allow_player_skip: bool = true

func get_next_candidates(_context: DialogueContext) -> Array[StringName]:
	if next_id == StringName():
		return []
	return [next_id]

func get_snippets() -> Array[DialogueSnippet]:
	return snippets

