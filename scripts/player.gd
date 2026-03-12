extends CharacterBody2D

signal jumped
signal landed
signal dashed
signal died

enum State { IDLE, WALK, RUN, AIRBORNE, WALL_SLIDE, DASH, HURT, DEAD }

@export var max_speed := 300.0
@export var acceleration := 1200.0
@export var deceleration := 1500.0
@export var air_acceleration := 600.0
@export var air_deceleration := 400.0
@export var jump_velocity := -450.0
@export var gravity := 1200.0
@export var fall_gravity_multiplier := 1.5
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var wall_slide_speed := 80.0
@export var wall_jump_velocity := Vector2(320.0, -420.0)
@export var wall_jump_duration := 0.28
@export var dash_speed := 600.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.85
@export var invincibility_duration := 1.2
@export var knockback_strength := Vector2(250.0, -200.0)
@export var double_jump_velocity := -380.0

var state: State = State.IDLE
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _wall_jump_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _invincibility_timer := 0.0
var _facing := 1.0
var _is_wall_sliding := false
var _is_dashing := false
var _has_double_jump := true
var _wall_direction := 0.0
var _was_on_floor := false
var _sprite: ColorRect


func _ready() -> void:
	_sprite = get_node_or_null("Visual")
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_jump()
	_handle_wall_slide()
	_handle_dash()
	move_and_slide()
	_update_state()
	_check_landed()


func _update_timers(delta: float) -> void:
	_coyote_timer = max(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)
	_wall_jump_timer = max(_wall_jump_timer - delta, 0.0)
	_dash_timer = max(_dash_timer - delta, 0.0)
	_dash_cooldown_timer = max(_dash_cooldown_timer - delta, 0.0)
	_invincibility_timer = max(_invincibility_timer - delta, 0.0)
	if is_on_floor():
		_coyote_timer = coyote_time
		_has_double_jump = true


func _apply_gravity(delta: float) -> void:
	if _is_dashing:
		return
	var g := gravity * (fall_gravity_multiplier if velocity.y > 0 else 1.0)
	velocity.y = min(velocity.y + g * delta, 800.0)


func _handle_movement(delta: float) -> void:
	if _is_dashing or _wall_jump_timer > 0.0:
		return
	var dir := Input.get_axis("move_left", "move_right")
	var accel := acceleration if is_on_floor() else air_acceleration
	var decel := deceleration if is_on_floor() else air_deceleration
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
		_facing = sign(dir)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	if _jump_buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			_perform_jump()
		elif _can_wall_jump():
			_perform_wall_jump()
		elif _has_double_jump and not is_on_floor():
			_perform_double_jump()
	if Input.is_action_just_released("jump") and velocity.y < -200.0:
		velocity.y *= 0.5


func _can_wall_jump() -> bool:
	if not is_on_wall():
		return false
	_wall_direction = get_wall_normal().x
	return _wall_direction != 0.0


func _perform_jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	jumped.emit()


func _perform_wall_jump() -> void:
	velocity.x = _wall_direction * wall_jump_velocity.x
	velocity.y = wall_jump_velocity.y
	_wall_jump_timer = wall_jump_duration
	_jump_buffer_timer = 0.0
	jumped.emit()


func _perform_double_jump() -> void:
	_has_double_jump = false
	velocity.y = double_jump_velocity
	_jump_buffer_timer = 0.0
	jumped.emit()


func _handle_wall_slide() -> void:
	if not is_on_wall() or is_on_floor():
		_is_wall_sliding = false
		return
	var dir := Input.get_axis("move_left", "move_right")
	_is_wall_sliding = velocity.y > 0.0 and dir == -get_wall_normal().x
	if _is_wall_sliding:
		velocity.y = min(velocity.y, wall_slide_speed)


func _handle_dash() -> void:
	if _is_dashing and _dash_timer <= 0.0:
		_is_dashing = false
		velocity.x = _facing * max_speed * 0.5
	if not _is_dashing and _dash_cooldown_timer <= 0.0 and Input.is_action_just_pressed("dash"):
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		velocity = Vector2(_facing * dash_speed, 0.0)
		dashed.emit()


func _update_state() -> void:
	if _is_dashing:
		state = State.DASH
	elif _is_wall_sliding:
		state = State.WALL_SLIDE
	elif not is_on_floor():
		state = State.AIRBORNE
	elif abs(velocity.x) > max_speed * 0.6:
		state = State.RUN
	elif abs(velocity.x) > 10.0:
		state = State.WALK
	else:
		state = State.IDLE
	if _sprite:
		_sprite.color = _get_state_color()


func _get_state_color() -> Color:
	if state == State.DASH:
		return Color(0.4, 1.0, 0.4)
	if state == State.WALL_SLIDE:
		return Color(1.0, 0.6, 1.0)
	if state == State.AIRBORNE:
		return Color(0.6, 0.8, 1.0)
	if state == State.HURT:
		return Color(1.0, 0.2, 0.2)
	return Color(0.4, 0.6, 1.0)


func _check_landed() -> void:
	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()


func take_damage(source_position: Vector2 = Vector2.ZERO) -> void:
	if _invincibility_timer > 0.0 or state == State.DEAD:
		return
	state = State.HURT
	_invincibility_timer = invincibility_duration
	var dir := sign(global_position.x - source_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity = Vector2(dir * knockback_strength.x, knockback_strength.y)
	GameManager.lose_life()


func collect_coin(value: int = 1) -> void:
	GameManager.add_coin(value)


func spring_launch(force: float) -> void:
	velocity.y = force
	_has_double_jump = true
