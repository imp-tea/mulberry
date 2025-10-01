extends Node

signal dialogue_started(graph_id: StringName, actor_id: StringName)
signal dialogue_finished(graph_id: StringName, actor_id: StringName, reason: String)
signal dialogue_effect(event_id: StringName, payload: Dictionary)
