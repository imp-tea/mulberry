extends CharacterBody2D

var TILESIZE = 64
var movement_state = "idle"
var facing = "-down"
var anim_speed = 1.5
var inventory_open = false
var current_hotbar_slot = 0
var hovered = false
@export var speed = TILESIZE*2
@export var inventory: Inventory

func _ready() -> void:
	PlayerVariables.inventory = inventory
	PlayerVariables.position = self.position
	PlayerVariables.tile = Global.get_tile(position)

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction.normalized() * speed
	if velocity.is_zero_approx():
		movement_state = "idle"
		$AnimatedSprite2D.speed_scale = 1.0
	else:
		movement_state = "walk"
		facing = input_to_dir(input_direction)
		$AnimatedSprite2D.speed_scale = anim_speed
	$AnimatedSprite2D.play(movement_state+facing)
	

func _physics_process(delta):
	get_input()
	move_and_slide()
	position = Vector2(round(position.x),round(position.y))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		#inventory.visible = not inventory.visible
		inventory_open = not inventory_open
		if not inventory_open:
			for i in range(inventory.cols, inventory.cols*inventory.rows):
				inventory.slots[i].visible = false
			inventory.inventory_grid.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		else:
			for slot in inventory.slots:
				slot.visible = true
			inventory.inventory_grid.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	if Input.is_action_just_pressed("interact"):
		var resource = load("res://sample_emily.dialogue")
		DialogueManager.show_dialogue_balloon(resource,"quest_gemstones_start")
	
	PlayerVariables.position = self.position
	PlayerVariables.tile = Global.get_tile(position)

func input_to_dir(input:Vector2):
	var ang = input.angle()
	if ang >= -PI/8 and ang <= PI/8:
		return "-right"
	elif ang > PI/8 and ang < 3*PI/8:
		return "-down-right"
	elif ang >= 3*PI/8 and ang <= 5*PI/8:
		return "-down"
	elif ang > 5*PI/8 and ang < 7*PI/8:
		return "-down-left"
	elif ang >= 7*PI/8  or ang <= -7*PI/8:
		return "-left"
	elif ang > -7*PI/8 and ang < -5*PI/8:
		return "-up-left"
	elif ang >= -5*PI/8 and ang <= -3*PI/8:
		return "-up"
	else:
		return "-up-right"

func _on_area_2d_area_entered(area):
	if area in get_tree().get_nodes_in_group("items"):
		self.inventory.add_item(area as Item, 1)

func _mouse_enter() -> void:
	var outline:ShaderMaterial = load("res://Shaders/outline.tres")
	outline.set_shader_parameter("number_of_images", Vector2(4,1))
	$AnimatedSprite2D.set_material(outline)
	self.hovered = true
	
func _mouse_exit() -> void:
	$AnimatedSprite2D.set_material(null)
	self.hovered = false
