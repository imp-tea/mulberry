extends Control
class_name Inventory

var inventory_item_scene = preload("res://Inventory/InventorySlot/InventoryItem/InventoryItem.tscn")

@export var rows: int = 3
@export var cols: int = 6

@export var inventory_grid: GridContainer

@export var inventory_slot_scene: PackedScene
var slots: Array[InventorySlot]

@export var tooltip: Tooltip # Must be shared among all instanesself


static var selected_item: Item = null


func _ready():
	inventory_grid.columns = cols
	for i in range(rows * cols):
		var slot = inventory_slot_scene.instantiate()
		slots.append(slot)
		inventory_grid.add_child(slot)
		slot.slot_input.connect(self._on_slot_input) # binding not necessary as
		slot.slot_hovered.connect(self._on_slot_hovered) # it does while emit() call
		if i >= cols:
			slot.visible = false
	tooltip.visible = false
	Global.inventory = self




func _process(delta):
	tooltip.global_position = get_global_mouse_position() + Vector2.ONE * 8
	if selected_item:
			tooltip.visible = false
			selected_item.global_position = get_global_mouse_position()

			# Check if item is being dragged outside inventory bounds (for dropping)
			if Input.is_action_just_released("ui_select") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) == false:
					var mouse_pos = get_global_mouse_position()
					var inventory_rect = inventory_grid.get_global_rect()

					# If released outside inventory area, drop the item
					if not inventory_rect.has_point(mouse_pos):
							if selected_item.item_type in ["Droppable", "Consumable"]:
									# Drop at player position or mouse position in world
									var drop_pos = PlayerVariables.position
									drop_item_to_world(selected_item, drop_pos)

									# Remove the item if amount is now 0
									if selected_item.amount <= 0:
											selected_item.queue_free()
											selected_item = null







func _on_slot_input(which: InventorySlot, action: InventorySlot.InventorySlotAction):
	# Select/deselect items
	if not selected_item:
		# Spliting only occurs if not item selected already
		if action == InventorySlot.InventorySlotAction.SELECT:
			selected_item = which.select_item()
		elif action == InventorySlot.InventorySlotAction.SPLIT:
			selected_item = which.split_item() # Split means selecting half amount
	else:
		selected_item = which.deselect_item(selected_item)



func _on_slot_hovered(which: InventorySlot, is_hovering: bool):
	if which.item:
		tooltip.set_text(which.item.item_name)
		tooltip.visible = is_hovering
	elif which.hint_item:
		tooltip.set_text(which.hint_item.item_name)
		tooltip.visible = is_hovering





# API::

# !DESTRUCTUVE (removes item itself from world  and adds its copy to inventory)
# Calling thius func impies that item is not already in inventory
func add_item(item: Item, amount: int) -> void:
	var _item: InventoryItem = inventory_item_scene.instantiate() # Duplicate

	# Determine item type via class hierarchy (check most specific first)
	var item_type = "Item"
	if item is Consumable:
			item_type = "Consumable"
	elif item is Plant:
			item_type = "Plant"
	elif item is Structure:
			item_type = "Structure"
	elif item is Placeable:
			item_type = "Placeable"
	elif item is Droppable:
			item_type = "Droppable"

	# Get scene path for reinstantiation
	var scene_path = item.scene_file_path

	_item.set_data(
			item.item_name, item.icon, item.is_stackable, amount, item_type, scene_path
	)
	item.queue_free() # Consume the item by inventory (by the end of frame)
	if item.is_stackable:
			for slot in slots:
					if slot.item and slot.item.item_name == _item.item_name: # if item and is of same type
							slot.item.amount += _item.amount
							return
	for slot in slots:
			if slot.item == null and slot.is_respecting_hint(_item):
					slot.item = _item
					slot.update_slot()
					return



# !DESTRUCTUVE (removes from inventory if retrieved)
#A function to remove item from inventory and return if it exists
func retrieve_item(_item_name: String) -> Item:
	for slot in slots:
		if slot.item and slot.item.item_name == _item_name:
			var copy_item := Item.new()
			copy_item.item_name = slot.item.item_name
			copy_item.name = copy_item.item_name
			copy_item.icon = slot.item.icon
			copy_item.is_stackable = slot.item.is_stackable
			if slot.item.amount > 1:
				slot.item.amount -= 1
			else:
				slot.remove_item()
			return copy_item
	return null



# !NON-DESTRUCTIVE (read-only function) to get all items in inventory
func all_items() -> Array[Item]:
	var items: Array[Item] = []
	for slot in slots:
		if slot.item:
			items.append(slot.item)
	return items



# ! NON-DESTRUCTUVE (read-only), returns all items of a particular type
func all(_name: String) -> Array[Item]:
	var items: Array[Item] = []
	for slot in slots:
		if slot.item and slot.item.item_name == _name:
			items.append(slot.item)
	return items



# !DESTRUCTUVE (removes all items of a particular type)
func remove_all(_name: String) -> void:
	for slot in slots:
		if slot.item and slot.item.item_name == _name:
			slot.remove_item()



# !DESTRUCTUVE (removes all items from inventory)
func clear_inventory() -> void:
	for slot in slots:
		slot.remove_item()

# Drop an item from inventory into the world at specified position
func drop_item_to_world(inventory_item: InventoryItem, drop_position: Vector2) -> void:
	if inventory_item.item_type not in ["Droppable", "Consumable"]:
			return  # Can't drop this type

	if inventory_item.world_scene_path.is_empty():
			push_error("Cannot drop item: no scene path stored")
			return

	# Reinstantiate the world item from its scene
	var world_item: Item = load(inventory_item.world_scene_path).instantiate()
	world_item.position = drop_position
	get_tree().current_scene.add_child(world_item)

	# Reduce inventory amount
	inventory_item.amount -= 1
