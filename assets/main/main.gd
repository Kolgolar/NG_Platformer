extends Control

@export var level: LevelBase


func _ready() -> void:
	level.player.hp_changed.connect(%HUD.set_hp_value)
