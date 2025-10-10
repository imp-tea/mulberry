extends Node
class_name Item

var icon_size = Vector2(16,16)
@export var item_name: String = ""
@export var icon: Texture2D
@export var is_stackable: bool = false
@onready var icon_scale:float

func _ready():
	add_to_group("items")
