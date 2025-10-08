extends Item
class_name Placeable

  # Called when item is placed in the world from inventory
  # Override in subclasses for custom placement behavior
func on_placed(tile:Vector2) -> void:
	pass
