extends AnimatableBody2D

@export var move_distance := 150.0
@export var move_speed := 80.0
@export var vertical := false

var _start_position: Vector2
var _direction := 1.0
var _traveled := 0.0


func _ready() -> void:
	_start_position = global_position


func _physics_process(delta: float) -> void:
	var step := move_speed * delta * _direction
	_traveled += abs(step)
	if vertical:
		global_position.y += step
	else:
		global_position.x += step
	if _traveled >= move_distance:
		_traveled = 0.0
		_direction *= -1.0
