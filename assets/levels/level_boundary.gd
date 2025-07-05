extends Area2D


@export var attack_params: AttackParams


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit"):
		body.hit(attack_params, global_position)
