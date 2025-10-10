extends Node2D

func _process(delta: float) -> void:
	position = PlayerVariables.facing_tile * Global.tile_size

#func _ready() -> void:
	#print(TileManager.get_terrain_type(Vector2(0,0)))
	#print(TileManager.is_tile_occupied(Vector2(0,0)))
