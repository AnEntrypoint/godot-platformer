extends Area2D

signal level_completed

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		level_completed.emit()
		print("LEVEL COMPLETED!")
