extends CharacterBody2D

var TILESIZE = 64
var movement_state = "idle"
var facing = "-down"
var anim_speed = 1.5
@export var speed = TILESIZE*2

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
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

func _process(delta: float) -> void:
	pass

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
