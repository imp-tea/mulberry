extends Node
class_name DialogueService

const DialogueGraph = preload("res://dialogue/resources/dialogue_graph.gd")
const DialogueNode = preload("res://dialogue/resources/dialogue_node.gd")
const DialogueLineNode = preload("res://dialogue/resources/dialogue_line_node.gd")
const DialogueChoiceNode = preload("res://dialogue/resources/dialogue_choice_node.gd")
const DialogueChoiceOption = preload("res://dialogue/resources/dialogue_choice_option.gd")
const DialogueJumpNode = preload("res://dialogue/resources/dialogue_jump_node.gd")
const DialogueEndNode = preload("res://dialogue/resources/dialogue_end_node.gd")
const DialogueAmbientBarkSet = preload("res://dialogue/resources/ambient_bark_set.gd")
const DialogueAmbientBark = preload("res://dialogue/resources/ambient_bark.gd")
const DialogueSnippet = preload("res://dialogue/resources/dialogue_snippet.gd")
const DialogueSession = preload("res://dialogue/core/dialogue_session.gd")
const DialogueContext = preload("res://dialogue/core/dialogue_context.gd")
const DialogueRuntimeState = preload("res://dialogue/core/dialogue_runtime_state.gd")

signal conversation_started(graph_id: StringName, actor_id: StringName, node_id: StringName, context: DialogueContext)
signal snippet_ready(graph_id: StringName, actor_id: StringName, node_id: StringName, snippet_id: StringName, payload: Dictionary)
signal snippet_display_completed(graph_id: StringName, actor_id: StringName, node_id: StringName, snippet_id: StringName)
signal conversation_advanced(graph_id: StringName, actor_id: StringName, node_id: StringName)
signal choice_presented(graph_id: StringName, actor_id: StringName, node_id: StringName, options: Array)
signal choice_selected(graph_id: StringName, actor_id: StringName, node_id: StringName, option_id: StringName)
signal conversation_finished(graph_id: StringName, actor_id: StringName, reason: String, summary: Dictionary)
signal effect_fired(effect_id: StringName, payload: Dictionary, runtime: DialogueRuntimeState)
signal bark_fired(set_id: StringName, bark_id: StringName, snippet_id: StringName, payload: Dictionary)

@export var preload_graphs: Array[DialogueGraph] = []
@export var preload_bark_sets: Array[DialogueAmbientBarkSet] = []
@export var default_player_id: StringName = StringName("player")
@export var enable_logging: bool = true

var _graphs: Dictionary = {}
var _bark_sets: Dictionary = {}
var _actors: Dictionary = {}
var _global_state: Dictionary = {
	"flags": {},
	"variables": {},
	"quests": {},
	"calendar": {},
	"relationships": {}
}
var _player_state: Dictionary = {
	"id": default_player_id,
	"name": "Player",
	"stats": {},
	"skills": {},
	"inventory": {}
}
var _conversation_state: DialogueSession = null
var _pending_snippet: DialogueSnippet = null
var _pending_snippet_runtime: DialogueRuntimeState = null
var _awaiting_display_complete: bool = false
var _cooldowns: Dictionary = {}
var _transcript: Array = []
var _signal_bus: Node = null

func _ready() -> void:
	for graph in preload_graphs:
		register_graph(graph)
	for bark_set in preload_bark_sets:
		register_bark_set(bark_set)
	_signal_bus = _find_signal_bus()
	_connect_signal_bus()
	_load_content_pack("res://dialogue/content/graphs", Callable(self, "register_graph"))
	_load_content_pack("res://dialogue/content/barks", Callable(self, "register_bark_set"))

func register_graph(graph: DialogueGraph) -> void:
	if graph == null:
		return
	graph.build_index()
	_graphs[graph.graph_id] = graph

func register_bark_set(bark_set: DialogueAmbientBarkSet) -> void:
	if bark_set == null:
		return
	_bark_sets[bark_set.set_id] = bark_set

func register_actor(actor_id: StringName, data: Dictionary = {}) -> void:
	var record := _actors.get(actor_id, {
		"id": actor_id,
		"flags": {},
		"memory": {
			"recent_lines": [],
			"recent_barks": []
		},
		"cooldowns": {},
		"variables": {}
	})
	for key in data.keys():
		record[key] = data[key]
	_actors[actor_id] = record

func update_player_state(data: Dictionary) -> void:
	for key in data.keys():
		_player_state[key] = data[key]

func get_actor_state(actor_id: StringName) -> Dictionary:
	return _actors.get(actor_id, {})

func get_graph(graph_id: StringName) -> DialogueGraph:
	return _graphs.get(graph_id)

func start_conversation(graph_id: StringName, actor_id: StringName, overrides: Dictionary = {}, metadata: Dictionary = {}) -> bool:
	if _conversation_state != null and not overrides.get("allow_interrupt", false):
		push_warning("DialogueService: conversation already running.")
		return false
	var graph := get_graph(graph_id)
	if graph == null:
		push_error("DialogueService: missing graph %s" % graph_id)
		return false
	var actor_record := _actors.get(actor_id, {
		"id": actor_id,
		"flags": {},
		"memory": {
			"recent_lines": [],
			"recent_barks": []
		},
		"cooldowns": {},
		"variables": {}
	})
	_actors[actor_id] = actor_record
	var seed := _compute_seed(graph_id, actor_id, metadata.get("seed_override", 0))
	var context := DialogueContext.new(_global_state, actor_record, _player_state, {}, overrides, seed, false)
	var session := DialogueSession.new(self, graph, actor_id, metadata.get("target_id", default_player_id), context, seed, metadata)
	if not session.start():
		push_error("DialogueService: graph %s missing entry node or entry unusable." % graph_id)
		return false
	_conversation_state = session
	_pending_snippet = null
	_pending_snippet_runtime = null
	_awaiting_display_complete = false
	_transcript.clear()
	emit_signal("conversation_started", graph_id, actor_id, session.current_node.id, context)
	_process_current_node()
	return true

func is_conversation_active() -> bool:
	return _conversation_state != null and not _conversation_state.finished

func get_active_context() -> DialogueContext:
	if _conversation_state == null:
		return null
	return _conversation_state.context

func notify_snippet_display_complete() -> void:
	if not _awaiting_display_complete:
		return
	_awaiting_display_complete = false
	if _conversation_state == null:
		return
	if _pending_snippet != null and _pending_snippet_runtime != null:
		_apply_effects(_pending_snippet.after_display_effects, _prepare_runtime(_pending_snippet_runtime, StringName("after_display")))
	emit_signal("snippet_display_completed", _conversation_state.graph.graph_id, _conversation_state.actor_id, _conversation_state.current_node.id, _pending_snippet.id)

func advance_from_snippet() -> void:
	if _pending_snippet != null and _pending_snippet_runtime != null:
		_apply_effects(_pending_snippet.after_input_effects, _prepare_runtime(_pending_snippet_runtime, StringName("after_input")))
	_pending_snippet = null
	_pending_snippet_runtime = null
	if _conversation_state == null:
		return
	if _conversation_state.has_more_snippets():
		_emit_next_snippet()
	else:
		_on_line_finished()

func select_choice(option_id: StringName) -> void:
	if _conversation_state == null:
		return
	var node = _conversation_state.current_node
	if node == null or not (node is DialogueChoiceNode):
		return
	var choice_node: DialogueChoiceNode = node
	var options := choice_node.eligible_options(_conversation_state.context)
	for option in options:
		if option.id == option_id:
			_apply_choice(option)
			return
	push_warning("DialogueService: choice %s not eligible." % option_id)

func cancel_conversation(reason: String = "cancelled") -> void:
	if _conversation_state == null:
		return
	_finish_conversation(reason, {"cancelled": true})

func emit_effect_event(effect_id: StringName, payload: Dictionary, runtime: DialogueRuntimeState) -> void:
	emit_signal("effect_fired", effect_id, payload, runtime)

func request_ambient_bark(set_id: StringName, actor_id: StringName, overrides: Dictionary = {}) -> Dictionary:
	var bark_set: DialogueAmbientBarkSet = _bark_sets.get(set_id)
	if bark_set == null:
		push_warning("DialogueService: bark set %s missing" % set_id)
		return {}
	var actor_record := _actors.get(actor_id, {})
	var seed := _compute_seed(set_id, actor_id, overrides.get("seed_override", 0))
	var context := DialogueContext.new(_global_state, actor_record, _player_state, {}, overrides, seed, false)
	var candidates := _filter_barks(bark_set, actor_id, context)
	if candidates.is_empty():
		return {}
	var selected := _choose_weighted_bark(candidates, seed)
	if selected == null:
		return {}
	var snippet := selected.get_snippet()
	if snippet == null:
		return {}
	var runtime := DialogueRuntimeState.new(self, set_id, selected.id, 0, StringName("bark"), context, {"actor_id": actor_id})
	_apply_effects(snippet.immediate_effects, runtime)
	var text := snippet.render_text(context)
	_apply_effects(snippet.after_display_effects, _prepare_runtime(runtime, StringName("after_display")))
	_apply_effects(snippet.after_input_effects, _prepare_runtime(runtime, StringName("after_input")))
	_register_cooldown(actor_id, selected)
	_update_actor_memory(actor_id, selected.id, "recent_barks", overrides.get("memory_window", 4))
	var payload := {
		"actor_id": actor_id,
		"text": text,
		"tags": selected.tags,
		"bark_id": selected.id
	}
	emit_signal("bark_fired", set_id, selected.id, snippet.id, payload)
	return payload

func _process_current_node() -> void:
	if _conversation_state == null or _conversation_state.current_node == null:
		_finish_conversation("no_node", {})
		return
	var node = _conversation_state.current_node
	if node is DialogueJumpNode:
		var jump: DialogueJumpNode = node
		if not _conversation_state.advance_to_node(jump.target_id):
			_finish_conversation("invalid_jump", {"target": jump.target_id})
			return
		_process_current_node()
		return
	_apply_effects(node.on_enter_effects, _make_node_runtime(node, StringName("on_enter")))
	emit_signal("conversation_advanced", _conversation_state.graph.graph_id, _conversation_state.actor_id, node.id)
	if node is DialogueLineNode:
		_emit_next_snippet()
	elif node is DialogueChoiceNode:
		_present_choices()
	elif node is DialogueEndNode:
		_finish_conversation("end_node", {"node_id": node.id})
	else:
		_on_line_finished()

func _emit_next_snippet() -> void:
	var snippet := _conversation_state.get_next_snippet()
	if snippet == null:
		_on_line_finished()
		return
	var line: DialogueLineNode = _conversation_state.current_node
	var runtime := _make_snippet_runtime(snippet)
	_pending_snippet = snippet
	_pending_snippet_runtime = runtime
	_apply_effects(snippet.immediate_effects, runtime)
	var text := snippet.render_text(_conversation_state.context)
	var payload := {
		"actor_id": _conversation_state.actor_id,
		"speaker_id": line.speaker_id,
		"address_to": line.address_to,
		"text": text,
		"raw_text": snippet.text,
		"tags": snippet.tags,
		"snippet_index": _conversation_state.current_snippet_index,
		"snippet_count": line.snippets.size(),
		"auto_advance": line.auto_advance,
		"auto_advance_delay": line.auto_advance_delay,
		"allow_player_skip": line.allow_player_skip
	}
	_awaiting_display_complete = true
	emit_signal("snippet_ready", _conversation_state.graph.graph_id, _conversation_state.actor_id, line.id, snippet.id, payload)
	_update_actor_memory(_conversation_state.actor_id, snippet.id, "recent_lines", 6)
	_transcript.append({
		"graph": _conversation_state.graph.graph_id,
		"node": line.id,
		"snippet": snippet.id,
		"text": text,
		"speaker": line.speaker_id,
		"time": Time.get_unix_time_from_system()
	})

func _on_line_finished() -> void:
	if _conversation_state == null:
		return
	var node = _conversation_state.current_node
	_apply_effects(node.on_exit_effects, _make_node_runtime(node, StringName("on_exit")))
	var next_nodes := _conversation_state.graph.get_next_nodes(node, _conversation_state.context)
	if next_nodes.is_empty():
		_finish_conversation("no_next", {"node_id": node.id})
		return
	var filtered := _filter_highest_priority(next_nodes)
	var target := _choose_weighted_node(filtered)
	if target == null:
		_finish_conversation("no_next", {"node_id": node.id})
		return
	if not _conversation_state.enter_node(target):
		_finish_conversation("invalid_transition", {"node_id": node.id, "target": target.id})
		return
	_process_current_node()

func _present_choices() -> void:
	var choice_node: DialogueChoiceNode = _conversation_state.current_node
	var options := choice_node.eligible_options(_conversation_state.context)
	if options.is_empty():
		_finish_conversation("no_choices", {"node_id": choice_node.id})
		return
	if options.size() == 1 and choice_node.auto_choose_single:
		_apply_choice(options[0])
		return
	var rendered := []
	for option in options:
		rendered.append({
			"id": option.id,
			"text": option.render_text(_conversation_state.context),
			"tags": option.tags,
			"weight": option.weight
		})
	emit_signal("choice_presented", _conversation_state.graph.graph_id, _conversation_state.actor_id, choice_node.id, rendered)

func _apply_choice(option: DialogueChoiceOption) -> void:
	var runtime := _make_node_runtime(_conversation_state.current_node, StringName("choice"))
	_apply_effects(option.on_select_effects, runtime)
	emit_signal("choice_selected", _conversation_state.graph.graph_id, _conversation_state.actor_id, _conversation_state.current_node.id, option.id)
	if option.next_id == StringName():
		_finish_conversation("choice_end", {"option": option.id})
		return
	if not _conversation_state.advance_to_node(option.next_id):
		_finish_conversation("invalid_choice_target", {"option": option.id, "target": option.next_id})
		return
	_process_current_node()

func _finish_conversation(reason: String, summary: Dictionary) -> void:
	if _conversation_state == null:
		return
	_conversation_state.mark_finished()
	emit_signal("conversation_finished", _conversation_state.graph.graph_id, _conversation_state.actor_id, reason, summary)
	_conversation_state = null
	_pending_snippet = null
	_pending_snippet_runtime = null
	_awaiting_display_complete = false

func _apply_effects(effects: Array, runtime: DialogueRuntimeState) -> void:
	if effects == null:
		return
	for effect in effects:
		if effect == null:
			continue
		var success := effect.apply(runtime)
		if not success and enable_logging:
			push_warning("DialogueService: effect %s returned false" % effect)

func _make_node_runtime(node: DialogueNode, timing: StringName) -> DialogueRuntimeState:
	return DialogueRuntimeState.new(self, _conversation_state.graph.graph_id, node.id, _conversation_state.current_snippet_index, timing, _conversation_state.context, {
		"actor_id": _conversation_state.actor_id
	})

func _make_snippet_runtime(snippet: DialogueSnippet) -> DialogueRuntimeState:
	return DialogueRuntimeState.new(self, _conversation_state.graph.graph_id, _conversation_state.current_node.id, _conversation_state.current_snippet_index, StringName("immediate"), _conversation_state.context, {
		"actor_id": _conversation_state.actor_id,
		"snippet_id": snippet.id
	})

func _prepare_runtime(runtime: DialogueRuntimeState, timing: StringName) -> DialogueRuntimeState:
	return DialogueRuntimeState.new(runtime.service, runtime.graph_id, runtime.node_id, runtime.snippet_index, timing, runtime.context, runtime.metadata)

func _compute_seed(a: StringName, b: StringName, extra := 0) -> int:
	var hash_input := "%s|%s|%s" % [a, b, extra]
	return hash(hash_input)

func _filter_highest_priority(nodes: Array) -> Array:
	if nodes.is_empty():
		return []
	var highest := -9223372036854775808
	var result: Array = []
	for node in nodes:
		if node == null:
			continue
		if result.is_empty():
			highest = node.priority
			result.append(node)
		elif node.priority > highest:
			highest = node.priority
			result.clear()
			result.append(node)
		elif node.priority == highest:
			result.append(node)
	return result

func _choose_weighted_node(nodes: Array) -> DialogueNode:
	if nodes.is_empty():
		return null
	if nodes.size() == 1:
		return nodes[0]
	var total := 0.0
	for node in nodes:
		total += max(0.01, node.weight)
	var roll := _conversation_state.make_rng_roll() * total
	for node in nodes:
		roll -= max(0.01, node.weight)
		if roll <= 0.0:
			return node
	return nodes.back()

func _load_content_pack(dir_path: String, register_callable: Callable) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path := dir_path.path_join(file_name)
				var res := ResourceLoader.load(resource_path)
				if res != null:
					register_callable.call(res)
				elif enable_logging:
					push_warning("DialogueService: failed to load %s" % resource_path)
		file_name = dir.get_next()
	dir.list_dir_end()
func _find_signal_bus() -> Node:
	if get_tree() == null:
		return null
	var root := get_tree().root
	if root == null:
		return null
	if root.has_node("SignalBus"):
		return root.get_node("SignalBus")
	return null

func _connect_signal_bus() -> void:
	if _signal_bus == null:
		return
	if not conversation_started.is_connected(_relay_bus_started):
		conversation_started.connect(_relay_bus_started)
	if not conversation_finished.is_connected(_relay_bus_finished):
		conversation_finished.connect(_relay_bus_finished)
	if not effect_fired.is_connected(_relay_bus_effect):
		effect_fired.connect(_relay_bus_effect)

func _relay_bus_started(graph_id: StringName, actor_id: StringName, _node_id: StringName, _context: DialogueContext) -> void:
	_signal_bus.emit_signal("dialogue_started", graph_id, actor_id)

func _relay_bus_finished(graph_id: StringName, actor_id: StringName, reason: String, _summary: Dictionary) -> void:
	_signal_bus.emit_signal("dialogue_finished", graph_id, actor_id, reason)

func _relay_bus_effect(effect_id: StringName, payload: Dictionary, _runtime: DialogueRuntimeState) -> void:
	_signal_bus.emit_signal("dialogue_effect", effect_id, payload)

func _filter_barks(bark_set: DialogueAmbientBarkSet, actor_id: StringName, context: DialogueContext) -> Array[DialogueAmbientBark]:
	var all := bark_set.eligible_barks(context)
	if all.is_empty():
		return []
	var highest := -9223372036854775808
	var filtered: Array[DialogueAmbientBark] = []
	for bark in all:
		if _bark_on_cooldown(actor_id, bark):
			continue
		if bark.priority > highest:
			highest = bark.priority
			filtered.clear()
			filtered.append(bark)
		elif bark.priority == highest:
			filtered.append(bark)
	return filtered

func _choose_weighted_bark(candidates: Array, seed: int) -> DialogueAmbientBark:
	if candidates.is_empty():
		return null
	var total := 0.0
	for bark in candidates:
		total += max(0.01, bark.weight)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pick := rng.randf() * total
	for bark in candidates:
		pick -= max(0.01, bark.weight)
		if pick <= 0.0:
			return bark
	return candidates.back()

func _register_cooldown(actor_id: StringName, bark: DialogueAmbientBark) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if bark.cooldown_scope == "global":
		_cooldowns[bark.id] = now + bark.cooldown_seconds
	elif bark.cooldown_scope == "location":
		var key := "%s|location" % bark.id
		_cooldowns[key] = now + bark.cooldown_seconds
	else:
		var actor := _actors.get(actor_id, {})
		var actor_cooldowns := actor.get("cooldowns", {})
		actor_cooldowns[bark.id] = now + bark.cooldown_seconds
		actor["cooldowns"] = actor_cooldowns
		_actors[actor_id] = actor

func _bark_on_cooldown(actor_id: StringName, bark: DialogueAmbientBark) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if bark.cooldown_scope == "global":
		return now < _cooldowns.get(bark.id, 0)
	elif bark.cooldown_scope == "location":
		var key := "%s|location" % bark.id
		return now < _cooldowns.get(key, 0)
	else:
		var actor := _actors.get(actor_id, {})
		var actor_cooldowns := actor.get("cooldowns", {})
		return now < actor_cooldowns.get(bark.id, 0)

func _update_actor_memory(actor_id: StringName, entry: StringName, channel: String, limit: int) -> void:
	var actor := _actors.get(actor_id, {})
	var memory := actor.get("memory", {})
	var bucket: Array = memory.get(channel, [])
	bucket.append(entry)
	while limit > 0 and bucket.size() > limit:
		bucket.pop_front()
	memory[channel] = bucket
	actor["memory"] = memory
	_actors[actor_id] = actor

func get_transcript() -> Array:
	return _transcript.duplicate(true)











