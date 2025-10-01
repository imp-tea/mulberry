extends "res://dialogue/conditions/dialogue_condition.gd"
class_name DialoguePropertyCondition

@export var property_path: String = ""
@export var operator: String = "=="
@export var expected_value: Variant
@export var case_insensitive: bool = false
@export var default_value: Variant = null

static var _operators := {
	"==": func(a, b): return a == b,
	"!=": func(a, b): return a != b,
	">": func(a, b): return a > b,
	">=": func(a, b): return a >= b,
	"<": func(a, b): return a < b,
	"<=": func(a, b): return a <= b,
	"contains": func(a, b):
		if typeof(a) == TYPE_STRING:
			return a.find(b) != -1
		elif typeof(a) == TYPE_ARRAY:
			return a.has(b)
		return false,
	"not_contains": func(a, b):
		if typeof(a) == TYPE_STRING:
			return a.find(b) == -1
		elif typeof(a) == TYPE_ARRAY:
			return not a.has(b)
		return true
}

func is_satisfied(context: DialogueContext) -> bool:
	if property_path.is_empty():
		return false
	var actual := context.resolve(property_path)
	if actual == null and default_value != null:
		actual = default_value
	var expected := expected_value
	if case_insensitive and typeof(actual) == TYPE_STRING and typeof(expected) == TYPE_STRING:
		actual = actual.to_lower()
		expected = expected.to_lower()
	var comparator = _operators.get(operator)
	if comparator == null:
		push_warning("Unknown operator %s on DialoguePropertyCondition %s" % [operator, id])
		return false
	return comparator.call(actual, expected)

func get_debug_state(context: DialogueContext) -> Dictionary:
	var actual := context.resolve(property_path)
	return {
		"id": id,
		"path": property_path,
		"operator": operator,
		"expected": expected_value,
		"actual": actual,
		"result": is_satisfied(context)
	}

