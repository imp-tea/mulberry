extends Node

var tile_size:int = 32
var half_tile:int = floori(tile_size/2)
var player:CharacterBody2D
var inventory:Inventory

func get_tile(pos:Vector2):
	return Vector2(floor(pos.x/tile_size),floor(pos.y/tile_size))

func add_to_inventory(item:Item, amount:int = 1):
	inventory.add_item(item, amount)
