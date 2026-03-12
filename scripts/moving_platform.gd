extends StaticBody2D

@export var move_distance := 150.0
@export var move_speed := 2.0
@export var wait_time := 0.5

var _start_position: Vector2
var _direction := 1.0
var _wait_timer := 0.0


func _ready() -> void:
	_start_position = global_position


func _physics_process(delta: float) -> void:
	if _wait_timer > 0:
		_wait_timer -= delta
		return

	global_position.x += _direction * move_speed * delta

	var distance_traveled: float = abs(global_position.x - _start_position.x)
	if distance_traveled >= move_distance:
		_direction *= -1
		_wait_timer = wait_time
