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
	PlayerVariables.facing_tile = get_facing_tile()
	Global.player = self

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
	  # Replace the interact section:
		  # Handle item placement with validation
	if Input.is_action_just_pressed("interact"):
		# Check if current hotbar slot has a placeable item
		var hotbar_item = inventory.slots[current_hotbar_slot].item

		if hotbar_item and hotbar_item.item_type in ["Placeable", "Plant", "Structure"]:
			# Get target tile (the tile the player is facing)
			var target_tile = PlayerVariables.facing_tile

			# Load the item temporarily to check placement validity
			if not hotbar_item.world_scene_path.is_empty():
				var temp_item: Placeable = load(hotbar_item.world_scene_path).instantiate()

				# Validate placement
				var validation = TileManager.can_place_item(temp_item, target_tile)

				if validation.valid:
					# Free temp item and place actual item
					temp_item.queue_free()
					place_item(hotbar_item, target_tile)
				else:
					# Show error feedback
					print("Cannot place: ", validation.reason)
					temp_item.queue_free()

	
	PlayerVariables.position = self.position
	PlayerVariables.tile = Global.get_tile(position)
	PlayerVariables.facing_tile = get_facing_tile()

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

func _mouse_enter() -> void:
	var outline:ShaderMaterial = load("res://Shaders/outline.tres")
	outline.set_shader_parameter("number_of_images", Vector2(4,1))
	$AnimatedSprite2D.set_material(outline)
	self.hovered = true
	
func _mouse_exit() -> void:
	$AnimatedSprite2D.set_material(null)
	self.hovered = false

# Get the tile the player is currently facing
func get_facing_tile() -> Vector2:
	var player_tile = Global.get_tile(position)
	var facing_offset = Vector2.ZERO

	# Determine offset based on facing direction
	if "right" in facing:
			facing_offset.x += 1
	elif "left" in facing:
			facing_offset.x -= 1

	if "down" in facing:
			facing_offset.y += 1
	elif "up" in facing:
			facing_offset.y -= 1

	return player_tile + facing_offset


# Place an item from inventory into the world
func place_item(inventory_item: InventoryItem, tile: Vector2):
	if inventory_item.world_scene_path.is_empty():
			push_error("Cannot place item: no scene path stored")
			return

	# Reinstantiate world item
	var world_item: Placeable = load(inventory_item.world_scene_path).instantiate()
	var world_position = tile * Global.tile_size + Vector2.ONE * Global.half_tile
	world_item.position = world_position
	get_tree().current_scene.add_child(world_item)
	
	# Register placement with TileManager
	TileManager.register_placement(tile, world_item)

	# Call placement hook if available
	if world_item.has_method("on_placed"):
			world_item.on_placed(tile)

	# Remove from inventory
	inventory_item.amount -= 1
	if inventory_item.amount <= 0:
			inventory.slots[current_hotbar_slot].remove_item()


#func _on_area_2d_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	#var top_node = area.get_owner()
	#print(top_node.name)
	#if top_node in get_tree().get_nodes_in_group("items"):
		#self.inventory.add_item(top_node as Item, 1)

func _on_area_2d_area_entered(area):
	var top_node = area.get_owner()
	print(top_node.name)
	if top_node in get_tree().get_nodes_in_group("pickup_items"):
		self.inventory.add_item(top_node as Item, 1)
