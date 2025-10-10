extends Node2D

func _process(delta: float) -> void:
	position = PlayerVariables.facing_tile * Global.tile_size
