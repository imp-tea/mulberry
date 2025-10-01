extends RefCounted
class_name DialogueRuntimeState

const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")

var service: Node
var graph_id: StringName
var node_id: StringName
var snippet_index: int = -1
var timing: StringName = "immediate"
var context: DialogueContext
var metadata: Dictionary = {}

func _init(service_ref:=null, graph:=StringName(), node:=StringName(), snippet:=-1, timing_label:=StringName("immediate"), ctx:=null, meta:={}):
	service = service_ref
	graph_id = graph
	node_id = node
	snippet_index = snippet
	timing = timing_label
	context = ctx if ctx != null else DialogueContext.new()
	metadata = meta.duplicate(true)

func emit_event(event_name: StringName, payload: Dictionary = {}) -> void:
	if service == null:
		return
	if service.has_method("emit_effect_event"):
		service.emit_effect_event(event_name, payload, self)

