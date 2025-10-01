extends CharacterBody2D

var TILESIZE = 64
@export var speed = TILESIZE * 1.5
@export var dialogue_graph_id: StringName = "customer_intro"
@export var dialogue_actor_id: StringName = "customer"
@export var ambient_bark_set_id: StringName = "customer_idle"
@export var display_name: String = "Hazel"
@export var interaction_radius: float = TILESIZE * 1.75

var movement_state = "idle"
var facing = "down"
var anim_speed = 1.5
signal stop_moving
signal start_moving

var _dialogue_service = null
var _player: Node2D = null
var _idle_bark_timer: Timer = null
var _player_near := false

func move_distance(dist:int, dir:String):
	var move_time = (float(dist)*float(TILESIZE))/float(speed)
	emit_signal("start_moving", move_time, dir)

func _physics_process(_delta):
	move_and_slide()

func _process(_delta: float) -> void:
	_ensure_player_reference()
	_update_player_proximity()
	if _player_near and Input.is_action_just_pressed("ui_accept"):
		_try_start_conversation()
	if _dialogue_service != null and _dialogue_service.is_conversation_active():
		velocity = Vector2.ZERO
		return
	if movement_state == "idle" and randf() > 0.997:
		var directions = ["up","down","left","right"]
		move_distance(randi_range(1,4), directions[randi_range(0,3)])

func _ready() -> void:
	$AnimatedSprite2D.play("idle-down")
	_dialogue_service = _get_dialogue_service()
	if _dialogue_service != null:
		_dialogue_service.register_actor(dialogue_actor_id, {"display_name": display_name})
		_dialogue_service.bark_fired.connect(_on_bark_fired)
	_initialize_bark_timer()

func input_to_dir(input:Vector2):
	var ang = input.angle()
	if ang >= -PI/8 and ang <= PI/8:
		return "right"
	elif ang > PI/8 and ang < 3*PI/8:
		return "down-right"
	elif ang >= 3*PI/8 and ang <= 5*PI/8:
		return "down"
	elif ang > 5*PI/8 and ang < 7*PI/8:
		return "down-left"
	elif ang >= 7*PI/8  or ang <= -7*PI/8:
		return "left"
	elif ang > -7*PI/8 and ang < -5*PI/8:
		return "up-left"
	elif ang >= -5*PI/8 and ang <= -3*PI/8:
		return "up"
	else:
		return "up-right"

func _on_stop_moving() -> void:
	velocity = Vector2.ZERO
	movement_state = "idle"
	$AnimatedSprite2D.play(movement_state+"-"+facing)

func _on_start_moving(time:float, dir:String) -> void:
	get_tree().create_timer(time, true).timeout.connect(_on_stop_moving)
	var dir_vec = Vector2.ZERO
	if dir == "up":
		dir_vec.y = -1
	elif dir == "down":
		dir_vec.y = 1
	elif dir == "left":
		dir_vec.x = -1
	elif dir == "right":
		dir_vec.x = 1
	velocity = dir_vec * speed
	movement_state = "walk"
	facing = dir
	$AnimatedSprite2D.play(movement_state+"-"+facing)

func _ensure_player_reference() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var parent_world = get_parent()
	if parent_world != null and parent_world.has_node("player"):
		_player = parent_world.get_node("player")

func _update_player_proximity() -> void:
	if _player == null or not is_instance_valid(_player):
		_player_near = false
		return
	_player_near = global_position.distance_to(_player.global_position) <= interaction_radius

func _try_start_conversation() -> void:
	if _dialogue_service == null:
		return
	if _dialogue_service.is_conversation_active():
		return
	_face_player()
	var overrides := {
		"actor.position": global_position,
		"player.position": (_player.global_position if _player != null else Vector2.ZERO)
	}
	_dialogue_service.start_conversation(dialogue_graph_id, dialogue_actor_id, overrides)

func _face_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := (_player.global_position - global_position).normalized()
	var dir = _vector_to_facing(to_player)
	if dir.is_empty():
		return
	facing = dir
	movement_state = "idle"
	$AnimatedSprite2D.play("idle-"+facing)

func _vector_to_facing(direction: Vector2) -> String:
	if direction.length() < 0.1:
		return facing
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"

func _initialize_bark_timer() -> void:
	if ambient_bark_set_id == StringName():
		return
	_idle_bark_timer = Timer.new()
	_idle_bark_timer.one_shot = false
	_idle_bark_timer.wait_time = randf_range(12.0, 20.0)
	add_child(_idle_bark_timer)
	_idle_bark_timer.timeout.connect(_on_idle_bark_timeout)
	_idle_bark_timer.start()

func _on_idle_bark_timeout() -> void:
	if _dialogue_service == null:
		return
	if _dialogue_service.is_conversation_active():
		return
	var overrides := {"actor.position": global_position}
	_dialogue_service.request_ambient_bark(ambient_bark_set_id, dialogue_actor_id, overrides)
	_idle_bark_timer.wait_time = randf_range(16.0, 28.0)

func _on_bark_fired(set_id: StringName, bark_id: StringName, snippet_id: StringName, payload: Dictionary) -> void:
	if payload.get("actor_id") != dialogue_actor_id:
		return
	if payload.has("text"):
		_show_bark_text(str(payload["text"]))

func _show_bark_text(message: String) -> void:
	if message.is_empty():
		return
	var label := Label.new()
	label.text = message
	label.z_index = 10
	label.modulate = Color(1, 1, 1, 0)
	label.position = Vector2(-48, -72)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.8)
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -12), 1.2).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(label.queue_free)

func _get_dialogue_service():
	if Engine.get_singleton_list().has(StringName("DialogueService")):
		return DialogueService
	return null


