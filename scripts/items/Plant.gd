extends Placeable
class_name Plant

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and Global.get_tile(self.position) == PlayerVariables.facing_tile:
		Global.add_to_inventory(self, 1)
