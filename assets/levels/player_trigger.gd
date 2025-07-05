extends Area2D

signal triggered


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		triggered.emit()
