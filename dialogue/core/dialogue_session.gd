extends RefCounted
class_name DialogueSession

const DialogueGraph = preload("res://dialogue/resources/dialogue_graph.gd")
const DialogueNode = preload("res://dialogue/resources/dialogue_node.gd")
const DialogueLineNode = preload("res://dialogue/resources/dialogue_line_node.gd")
const DialogueChoiceNode = preload("res://dialogue/resources/dialogue_choice_node.gd")
const DialogueChoiceOption = preload("res://dialogue/resources/dialogue_choice_option.gd")
const DialogueEndNode = preload("res://dialogue/resources/dialogue_end_node.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

var service: Node
var graph: DialogueGraph
var actor_id: StringName
var target_id: StringName
var context: DialogueContext
var metadata: Dictionary = {}

var current_node: DialogueNode
var current_snippet_index: int = -1
var finished: bool = false
var rng := RandomNumberGenerator.new()

var node_history: Array[StringName] = []
var snippet_history: Array[StringName] = []
var visit_counts: Dictionary = {}

func _init(service_ref:=null, graph_ref:=null, actor:=StringName(), target:=StringName(), ctx:=null, seed:=0, meta:={}) -> void:
	service = service_ref
	graph = graph_ref
	actor_id = actor
	target_id = target
	context = ctx
	metadata = meta.duplicate(true)
	rng.seed = seed

func start() -> bool:
	if graph == null:
		return false
	var entry := graph.get_entry_node(context)
	if entry == null:
		return false
	return enter_node(entry)

func enter_node(node: DialogueNode) -> bool:
	if node == null:
		return false
	current_node = node
	current_snippet_index = -1
	node_history.append(node.id)
	visit_counts[node.id] = visit_counts.get(node.id, 0) + 1
	finished = node is DialogueEndNode
	return true

func get_next_snippet() -> Resource:
	if finished or current_node == null:
		return null
	if current_node is DialogueLineNode:
		var line: DialogueLineNode = current_node
		current_snippet_index += 1
		if current_snippet_index < line.snippets.size():
			var snippet := line.snippets[current_snippet_index]
			if snippet != null:
				snippet_history.append(snippet.id)
			return snippet
	return null

func has_more_snippets() -> bool:
	if current_node is DialogueLineNode:
		var line: DialogueLineNode = current_node
		return current_snippet_index + 1 < line.snippets.size()
	return false

func get_current_snippet() -> Resource:
	if current_node is DialogueLineNode:
		var line: DialogueLineNode = current_node
		if current_snippet_index >= 0 and current_snippet_index < line.snippets.size():
			return line.snippets[current_snippet_index]
	return null

func collect_choices() -> Array[DialogueChoiceOption]:
	if current_node is DialogueChoiceNode:
		var choice: DialogueChoiceNode = current_node
		return choice.eligible_options(context)
	return []

func advance_to_node(node_id: StringName) -> bool:
	var next_node := graph.get_node(node_id)
	return enter_node(next_node)

func make_rng_roll() -> float:
	return rng.randf()

func mark_finished() -> void:
	finished = true

