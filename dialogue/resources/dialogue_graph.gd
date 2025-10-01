extends Resource
class_name DialogueGraph

const DialogueNode = preload("res://dialogue/resources/dialogue_node.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

@export var graph_id: StringName
@export var entry_node_id: StringName
@export var title: String = ""
@export var description: String = ""
@export var nodes: Array[DialogueNode] = []
@export var metadata: Dictionary = {}

var _node_map: Dictionary = {}

func _ready() -> void:
	build_index()

func build_index() -> void:
	_node_map.clear()
	for node in nodes:
		if node != null and node.id != StringName():
			_node_map[node.id] = node

func get_node(node_id: StringName) -> DialogueNode:
	if _node_map.is_empty():
		build_index()
	return _node_map.get(node_id)

func get_entry_node(context: DialogueContext) -> DialogueNode:
	var entry := get_node(entry_node_id)
	if entry != null and entry.is_eligible(context):
		return entry
	return _find_first_eligible(context)

func _find_first_eligible(context: DialogueContext) -> DialogueNode:
	for node in nodes:
		if node != null and node.is_eligible(context):
			return node
	return null

func get_next_nodes(node: DialogueNode, context: DialogueContext) -> Array[DialogueNode]:
	if node == null:
		return []
	var candidates: Array[StringName] = node.get_next_candidates(context)
	var output: Array[DialogueNode] = []
	for id in candidates:
		var candidate := get_node(id)
		if candidate != null and candidate.is_eligible(context):
			output.append(candidate)
	return output

func validate(out_errors: Array) -> bool:
	build_index()
	var ok := true
	if entry_node_id == StringName():
		out_errors.append("Graph %s has no entry node." % graph_id)
		ok = false
	if not _node_map.has(entry_node_id):
		out_errors.append("Graph %s missing entry node %s." % [graph_id, entry_node_id])
		ok = false
	for node in nodes:
		if node == null:
			out_errors.append("Graph %s contains null node slot." % graph_id)
			ok = false
		else:
			for next_id in node.get_next_candidates(DialogueContext.new()):
				if next_id != StringName() and not _node_map.has(next_id):
					out_errors.append("Node %s references missing node %s." % [node.id, next_id])
					ok = false
	return ok

