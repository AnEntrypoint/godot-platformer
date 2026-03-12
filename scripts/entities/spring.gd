extends Area2D

@export var launch_force := -900.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("spring_launch"):
		body.spring_launch(launch_force)
