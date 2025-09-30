extends CharacterBody2D

var TILESIZE = 64
@export var speed = TILESIZE * 1.5
var movement_state = "idle"
var facing = "-down"
var anim_speed = 1.5
signal stop_moving
signal start_moving

func move_distance(dist:int, dir:String):
	var move_time = (float(dist)*float(TILESIZE))/float(speed)
	emit_signal("start_moving", move_time, dir)

func _physics_process(_delta):
	move_and_slide()

func _process(_delta: float) -> void:
	if movement_state == "idle" and randf() > 0.997:
		var directions = ["up","down","left","right"]
		move_distance(randi_range(1,4), directions[randi_range(0,3)])

func _ready() -> void:
	$AnimatedSprite2D.play("idle-down")

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
