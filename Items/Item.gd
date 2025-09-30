extends Node
class_name Item

var icon_size = Vector2(16,16)
@export var item_name: String = ""
@export var icon: Texture2D
@export var is_stackable: bool = false
@onready var icon_scale:float
@onready var is_placeable:bool = false
func _ready():
	icon_scale = min(icon_size.x/icon.get_size().x, icon_size.y/icon.get_size().y)
	add_to_group("items")
