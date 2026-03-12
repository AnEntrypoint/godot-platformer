extends Area2D

signal collected

@export var value := 1

var _collected := false

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is CharacterBody2D:
		_collected = true
		collected.emit(value)
		queue_free()
