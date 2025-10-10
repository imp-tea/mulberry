extends Node2D

@onready var sprite = $Sprite2D

func _process(delta: float) -> void:
	position = PlayerVariables.facing_tile * Global.tile_size
	
	# Visual feedback for placement validity
	update_placement_feedback()

func update_placement_feedback() -> void:
	# Get the current hotbar item
	if not PlayerVariables.inventory:
		sprite.modulate = Color.WHITE
		return
	
	var player = Global.player
	if not player:
		sprite.modulate = Color.WHITE
		return
	
	var hotbar_item = PlayerVariables.inventory.slots[player.current_hotbar_slot].item
	
	# If no placeable item in hotbar, show default white outline
	if not hotbar_item or hotbar_item.item_type not in ["Placeable", "Plant", "Structure"]:
		sprite.modulate = Color.WHITE
		return
	
	# Load item temporarily to check placement validity
	if hotbar_item.world_scene_path.is_empty():
		sprite.modulate = Color.WHITE
		return
	
	var temp_item: Placeable = load(hotbar_item.world_scene_path).instantiate()
	var validation = TileManager.can_place_item(temp_item, PlayerVariables.facing_tile)
	temp_item.queue_free()
	
	# Color code based on validity
	if validation.valid:
		sprite.modulate = Color(0.3, 1.0, 0.3, 0.8)  # Green for valid
	else:
		sprite.modulate = Color(1.0, 0.3, 0.3, 0.8)  # Red for invalid
