extends Placeable
class_name Structure

@export var requires_tool_to_pickup: bool = true

# Override to add custom pickup requirements (distance check, tool check, etc.)
func can_pickup() -> bool:
	# Check if player is close enough
	var player_pos = PlayerVariables.position
	var distance = self.position.distance_to(player_pos)
	if distance > 64:  # Within ~2 tiles
			return false

	# Add tool requirement check here if needed
	if requires_tool_to_pickup:
			# TODO: Check if player has required tool in inventory
			pass

	return true

# Called when player interacts with the structure
func pickup() -> void:
	if not can_pickup():
			return
	
	# Get tile position before removal
	var tile = Global.get_tile(self.position)
	TileManager.unregister_placement(tile)

	# Convert back to inventory item
	if PlayerVariables.inventory:
			# Create a temporary item to add back to inventory
			var temp_item = duplicate()
			PlayerVariables.inventory.add_item(temp_item, 1)

	queue_free()
