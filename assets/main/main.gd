extends Control

@export var level: LevelBase

var is_game_ended := false


func _ready() -> void:
	randomize()
	level.game_over.connect(_on_level_test_game_over)
	level.player.hp_changed.connect(%HUD.set_hp_value)
	level.player.max_hp_changed.connect(%HUD.set_max_hp_value)


func _on_level_test_game_over(is_player_won: bool) -> void:
	%HUD.set_game_over(true, is_player_won)
	is_game_ended = true


func _unhandled_input(event: InputEvent) -> void:
	if is_game_ended:
		if event.is_action_pressed("game_restart"):
			get_tree().reload_current_scene()
	else:
		if event.is_action_pressed("game_restart"):
			%RestartHoldTimer.start()
		elif event.is_action_released("game_restart"):
			%RestartHoldTimer.stop()


func _on_restart_hold_timer_timeout() -> void:
	get_tree().reload_current_scene()
