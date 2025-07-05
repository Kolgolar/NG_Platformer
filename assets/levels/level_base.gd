class_name LevelBase
extends Node2D

signal game_over(is_player_won: bool)
signal enemy_killed

var total_enemies := 0
var killed_enemies := 0

@export var player: Player


func _ready() -> void:
	player.dead.connect(_on_player_dead)
	var all_enemies := get_all_enemies()
	total_enemies = all_enemies.size()
	for enemy in all_enemies:
		enemy.dead.connect(_on_enemy_dead)


func get_all_enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemy")


func _on_enemy_dead() -> void:
	killed_enemies += 1
	enemy_killed.emit()


func _on_player_dead() -> void:
	game_over.emit(false)


func _on_end_level_trigger_triggered() -> void:
	game_over.emit(true)
	player.is_control_locked = true
