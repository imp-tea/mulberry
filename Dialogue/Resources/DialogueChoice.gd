extends Resource
class_name DialogueChoice

@export var text: String = ""
@export var next_node: DialogueNode
@export var disabled_text: String = ""  # If conditions not met (for future)
