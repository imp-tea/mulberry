extends Node

# TileManager - Centralized tile state management system
# Tracks occupancy, terrain types, and placement validation

  # PlacementResult class - returned by validation checks
class PlacementResult:
	var valid: bool = false
	var reason: String = ""
	func _init(is_valid: bool = false, fail_reason: String = ""):
		valid = is_valid
		reason = fail_reason


# Dictionary to store tile state data
# Key: Vector2 (tile coordinate)
# Value: Dictionary with tile state information
var tile_data: Dictionary = {}

# Reference to the main TileMapLayer for terrain queries
var tilemap: TileMapLayer = null

func _ready() -> void:
	# Wait for scene tree to be ready before finding tilemap
	call_deferred("_initialize")

func _initialize() -> void:
	# Find the tilemap node (tagged with "tilemap" group)
	var tilemaps = get_tree().get_nodes_in_group("tilemap")
	if tilemaps.size() > 0:
		tilemap = tilemaps[0]
		print("TileManager: Found tilemap")
	else:
		push_warning("TileManager: No tilemap found in 'tilemap' group")

# Get terrain type for a given tile coordinate
func get_terrain_type(tile: Vector2) -> String:
	if tilemap == null:
		push_warning("TileManager: Tilemap not initialized")
		return "unknown"

	# Get tile data from the tilemap
	var tile_data_obj = tilemap.get_cell_tile_data(tile)
	if tile_data_obj == null:
		return "unknown"

	# Get terrain set and terrain ID
	var terrain_set = tile_data_obj.terrain_set
	if terrain_set == -1:
		return "unknown"

	var terrain_id = tile_data_obj.terrain
	if terrain_id == -1:
		return "unknown"

	# Get the terrain name from the tileset
	var tileset = tilemap.tile_set
	if tileset == null:
		return "unknown"

	# Get terrain name from the tileset
	var terrain_name = tileset.get_terrain_name(terrain_set, terrain_id)
	return terrain_name.to_lower()

# Check if a tile is occupied by a placed item
func is_tile_occupied(tile: Vector2) -> bool:
	if not tile_data.has(tile):
		return false
	return tile_data[tile].get("occupied_by", null) != null

# Get the item/structure occupying a tile (if any)
func get_occupying_item(tile: Vector2) -> Node:
	if not tile_data.has(tile):
		return null
	return tile_data[tile].get("occupied_by", null)

# Register a placed item at a specific tile
func register_placement(tile: Vector2, item: Node) -> void:
	if not tile_data.has(tile):
		tile_data[tile] = {}

	tile_data[tile]["occupied_by"] = item
	tile_data[tile]["placed_item_type"] = item.get_class()

	# Store terrain type for quick access
	tile_data[tile]["terrain_type"] = get_terrain_type(tile)

	print("TileManager: Registered placement at ", tile, " - ", item.name)

# Unregister a placed item from a tile
func unregister_placement(tile: Vector2) -> void:
	if tile_data.has(tile):
		tile_data[tile].erase("occupied_by")
		tile_data[tile].erase("placed_item_type")

		# Clean up empty tile data entries
		if tile_data[tile].is_empty():
			tile_data.erase(tile)

		print("TileManager: Unregistered placement at ", tile)

# Get all tile state data for a specific tile
func get_tile_state(tile: Vector2) -> Dictionary:
	if not tile_data.has(tile):
		return {
			"terrain_type": get_terrain_type(tile),
			"occupied_by": null,
			"placed_item_type": null
		}
	return tile_data[tile].duplicate()

# Clear all tile data (useful for new game/loading)
func clear_all_data() -> void:
	tile_data.clear()
	print("TileManager: Cleared all tile data")

# Validate if an item can be placed at a specific tile
func can_place_item(item: Placeable, tile: Vector2) -> PlacementResult:
	# Check 1: Tile already occupied?
	if is_tile_occupied(tile):
		return PlacementResult.new(false, "Tile already occupied")
	
	# Check 2: Get terrain type
	var terrain = get_terrain_type(tile)
	if terrain == "unknown":
		return PlacementResult.new(false, "Invalid tile")
	
  	# Check 3: Item terrain requirements met?
	if not item.can_place_on_terrain(terrain):
		return PlacementResult.new(false, "Cannot place on " + terrain)

  	# Check 4: Custom item requirements (if method exists)
	if item.has_method("custom_placement_check"):
		var custom_result = item.custom_placement_check(tile)
		if not custom_result.valid:
			return custom_result
	
	# All checks passed
	return PlacementResult.new(true, "")


# Debug: Print tile state
func debug_print_tile(tile: Vector2) -> void:
	var state = get_tile_state(tile)
	print("=== Tile State at ", tile, " ===")
	print("  Terrain: ", state.get("terrain_type", "unknown"))
	print("  Occupied: ", state.get("occupied_by", "none"))
	print("  Item Type: ", state.get("placed_item_type", "none"))
