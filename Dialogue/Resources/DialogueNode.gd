extends Resource
class_name DialogueNode

enum NodeType { LINE, CHOICE_HUB, END }

@export var node_id: String = ""
@export var type: NodeType = NodeType.LINE
@export var text: String = ""
@export var speaker_override: String = ""  # Optional different speaker
@export var next_node: DialogueNode  # For LINE nodes
@export var choices: Array[DialogueChoice] = []  # For CHOICE_HUB nodes
@export var tags: Dictionary = {}  # Emotes, camera cues, sound effects
