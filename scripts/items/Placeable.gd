extends Item
class_name Placeable

# Terrain placement requirements
@export var allowed_terrains: Array[String] = []  # Empty = any terrain allowed
@export var blocked_terrains: Array[String] = []  # Terrains where placement is forbidden
@export var can_be_stacked_on:bool
@export var picked_up_on_interaction:bool = true

# Check if item can be placed on a specific terrain type
func can_place_on_terrain(terrain: String) -> bool:
	# If no restrictions, allow all terrains
	if allowed_terrains.is_empty() and blocked_terrains.is_empty():
		return true

	# Check blocklist first
	if terrain in blocked_terrains:
		return false

	# If allowlist exists, must be in it
	if not allowed_terrains.is_empty():
		return terrain in allowed_terrains
	return true

# Called when item is placed in the world from inventory
# Override in subclasses for custom placement behavior
func on_placed(tile: Vector2) -> void:
	TileManager.register_placement(tile, self)

# Override this in subclasses for custom placement validation
# Must return a TileManager.PlacementResult
func custom_placement_check(tile: Vector2) -> TileManager.PlacementResult:
	return TileManager.PlacementResult.new(true, "")

func _ready():
	on_placed(Global.get_tile(self.position))
