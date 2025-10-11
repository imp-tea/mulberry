extends Node2D
class_name DroppedItem

# DroppedItem - Wrapper for items that are "loose" in the world
# Used for items dropped from inventory, loot from destroyed objects, etc.
# These items can be picked up by walking over them (added to "pickup_items" group)

@export var item_name: String = ""
@export var icon: Texture2D
@export var is_stackable: bool = false
@export var amount: int = 1

# Internal state
var item_type: String = "Item"
var world_scene_path: String = ""
var can_be_picked_up: bool = false
var pickup_delay: float = 0.5  # Delay before item can be picked up

# Animation properties
var start_position: Vector2
var target_position: Vector2
var animation_time: float = 0.0
var animation_duration: float = 0.4  # Duration of arc animation
var arc_height: float = 32.0  # How high the item "bounces"
var is_animating: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var pickup_timer: Timer = $PickupTimer

func _ready() -> void:
	# Set up sprite (fixed 16x16 size)
	if icon:
		sprite.texture = icon
		# Scale sprite to 16x16 (half the global tile size of 32)
		var texture_size = icon.get_size()
		sprite.scale = Vector2(16.0 / texture_size.x, 16.0 / texture_size.y)

	# Start pickup delay timer
	pickup_timer.wait_time = pickup_delay
	pickup_timer.one_shot = true
	pickup_timer.timeout.connect(_on_pickup_timer_timeout)
	pickup_timer.start()

	# Wait until timer expires before adding to pickup group
	await pickup_timer.timeout
	add_to_group("pickup_items")

func _process(delta: float) -> void:
	if is_animating:
		animation_time += delta
		var progress = animation_time / animation_duration

		if progress >= 1.0:
			# Animation complete
			position = target_position
			is_animating = false
		else:
			# Lerp horizontal position
			position = start_position.lerp(target_position, progress)

			# Add arc (parabolic motion for vertical offset)
			var arc_progress = 1.0 - abs(2.0 * progress - 1.0)  # 0 -> 1 -> 0
			sprite.position.y = -arc_height * arc_progress

func _on_pickup_timer_timeout() -> void:
	can_be_picked_up = true

# Set item data (called when creating from inventory)
func set_item_data(_name: String, _icon: Texture2D, _is_stackable: bool, _amount: int, _type: String, _scene_path: String) -> void:
	item_name = _name
	icon = _icon
	is_stackable = _is_stackable
	amount = _amount
	item_type = _type
	world_scene_path = _scene_path

	if sprite and icon:
		sprite.texture = icon
		# Scale sprite to 16x16
		var texture_size = icon.get_size()
		sprite.scale = Vector2(16.0 / texture_size.x, 16.0 / texture_size.y)

# Eject the item in a random direction with arc animation
func eject(from_position: Vector2, min_distance: float = 24.0, max_distance: float = 48.0) -> void:
	start_position = from_position

	# Random angle and distance
	var angle = randf() * TAU
	var distance = randf_range(min_distance, max_distance)
	var direction = Vector2(cos(angle), sin(angle))

	target_position = start_position + direction * distance
	position = start_position

	# Start animation
	animation_time = 0.0
	is_animating = true
