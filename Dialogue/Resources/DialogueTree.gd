extends Resource
class_name DialogueTree

@export var tree_id: String = ""  # Stable ID for save/load
@export var root_node: DialogueNode
@export var variables: Dictionary = {}  # Template variables for future use
