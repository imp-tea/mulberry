extends RefCounted
class_name DialogueContext

var global_state: Dictionary
var actor_state: Dictionary
var player_state: Dictionary
var conversation_state: Dictionary
var extras: Dictionary
var random_seed: int = 0

var _owns_data := true

func _init(global:= {}, actor:= {}, player:= {}, conversation:= {}, extra:= {}, seed:=0, duplicate_data:=true) -> void:
	_owns_data = duplicate_data
	global_state = _prepare_store(global)
	actor_state = _prepare_store(actor)
	player_state = _prepare_store(player)
	conversation_state = _prepare_store(conversation)
	extras = _prepare_store(extra)
	random_seed = seed

func duplicate(deep:=true) -> DialogueContext:
	return DialogueContext.new(global_state, actor_state, player_state, conversation_state, extras, random_seed, deep)

func resolve(path: String) -> Variant:
	if path.is_empty():
		return null
	var segments := path.split(".")
	var value: Variant = _resolve_root(segments[0])
	for i in range(1, segments.size()):
		if value == null:
			return null
		value = _resolve_step(value, segments[i])
	return value

func set_value(path: String, value: Variant) -> void:
	if path.is_empty():
		return
	var segments := path.split(".")
	var container: Variant = _resolve_root(segments[0])
	if container == null:
		return
	for i in range(1, segments.size() - 1):
		container = _resolve_step(container, segments[i])
	if container == null:
		return
	var leaf := segments.back()
	match typeof(container):
		TYPE_DICTIONARY:
			container[leaf] = value
		TYPE_OBJECT:
			if container.has_method("set"):
				container.set(leaf, value)
		TYPE_ARRAY:
			var index := leaf.to_int()
			if index >= 0 and index < container.size():
				container[index] = value

func _prepare_store(source: Variant) -> Variant:
	if _owns_data and (source is Dictionary or source is Array):
		return source.duplicate(true)
	return source

func _resolve_root(root: String) -> Variant:
	match root:
		"global":
			return global_state
		"actor":
			return actor_state
		"player":
			return player_state
		"conversation":
			return conversation_state
		"extra":
			return extras
		_:
			return extras.get(root)

func _resolve_step(value: Variant, key: String) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			return value.get(key)
		TYPE_OBJECT:
			if value.has_method(key):
				return value.call(key)
			elif value.has_method("get"):
				return value.call("get", key)
			return null
		TYPE_ARRAY:
			var index := key.to_int()
			if index >= 0 and index < value.size():
				return value[index]
			return null
		_:
			return null

