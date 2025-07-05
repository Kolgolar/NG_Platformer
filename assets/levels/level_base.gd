class_name LevelBase
extends Node2D

signal game_over(is_player_won: bool)

@export var player: Player


func _ready() -> void:
	player.dead.connect(_on_player_dead)


func _on_player_dead():
	game_over.emit(false)


func _on_world_boundary_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).hit(99999999, 0, Vector2.ZERO)
