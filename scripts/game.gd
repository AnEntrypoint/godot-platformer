extends Node2D

@export var player_scene: PackedScene

var _player: Node2D

func _ready() -> void:
	_spawn_player()

func _spawn_player() -> void:
	if not player_scene:
		return
	_player = player_scene.instantiate()
	add_child(_player)
	_player.global_position = Vector2(150, 300)
