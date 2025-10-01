extends "res://dialogue/effects/dialogue_effect.gd"
class_name DialogueSetPropertyEffect

@export var property_path: String = "global.flags.example"
@export var operation: String = "set" # set, toggle, increment, decrement
@export var value: Variant

func apply(runtime: DialogueRuntimeState) -> bool:
	var ctx := runtime.context
	if ctx == null:
		return false
	var current := ctx.resolve(property_path)
	match operation:
		"set":
			ctx.set_value(property_path, value)
		"toggle":
			ctx.set_value(property_path, not bool(current))
		"increment":
			ctx.set_value(property_path, (current if current != null else 0) + value)
		"decrement":
			ctx.set_value(property_path, (current if current != null else 0) - value)
		_:
			ctx.set_value(property_path, value)
	return super.apply(runtime)

