extends CharacterBody2D
class_name BaseNPC

@export var npc_id: String = ""  # Unique ID
@export var npc_name: String = "NPC"
@export var dialogue_trees: Array[DialogueTree] = []
@export var can_initiate_conversation: bool = true
@export var interaction_range: float = 64.0

var dialogue_memory: Dictionary = {}  # Tracked by DialogueService

func _ready():
	add_to_group("npcs")
	DialogueService.register_npc(self)

func can_talk_to_player() -> bool:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player = players[0]
	return global_position.distance_to(player.global_position) <= interaction_range

func start_conversation():
	if can_talk_to_player() and can_initiate_conversation:
		DialogueService.start_conversation(self)
