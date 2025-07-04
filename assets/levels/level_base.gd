class_name LevelBase
extends Node2D

@export var player: Player



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_restart"):
		get_tree().reload_current_scene()
