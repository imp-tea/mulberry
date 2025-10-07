extends Node2D

func _process(delta: float) -> void:
	position = PlayerVariables.tile * Global.tile_size
