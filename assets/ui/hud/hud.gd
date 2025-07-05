extends Control



func _ready() -> void:
	set_game_over(false, false)


func set_game_over(enabled: bool, is_win: bool):
	%GameWonLabel.visible = enabled && is_win
	%GameLostLabel.visible = enabled && !is_win


func set_kills_label_text(text_to_display: String):
	%KillsLabel.text = text_to_display


func set_max_hp_value(value: float):
	%HP_Bar.max_value = value


func set_hp_value(value: float):
	%HP_Bar.value = value
