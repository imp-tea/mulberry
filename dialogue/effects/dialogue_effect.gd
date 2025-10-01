extends Resource
class_name DialogueEffect

const DialogueRuntimeState = preload("res://dialogue/core/dialogue_runtime_state.gd")

@export var id: StringName
@export var description: String = ""
@export var fire_event: StringName
@export var event_payload: Dictionary = {}

func apply(runtime: DialogueRuntimeState) -> bool:
	if fire_event != StringName():
		runtime.emit_event(fire_event, event_payload)
	return true

func get_debug_payload(runtime: DialogueRuntimeState) -> Dictionary:
	return {
		"id": id,
		"description": description,
		"event": fire_event,
		"payload": event_payload
	}

