extends Area2D

signal player_hit

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_hit.emit()
		respawn_player(body)

func respawn_player(player: CharacterBody2D) -> void:
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(150, 300)
