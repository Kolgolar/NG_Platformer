extends Control



func _ready() -> void:
	set_game_over(false, false)


func set_game_over(enabled: bool, is_win: bool) -> void:
	%GameWonLabel.visible = enabled && is_win
	%GameLostLabel.visible = enabled && !is_win


func set_kills_label_text(text_to_display: String) -> void:
	%KillsLabel.text = text_to_display


func set_max_hp_value(value: float) -> void:
	%HP_Bar.max_value = value


func set_hp_value(value: float) -> void:
	%HP_Bar.value = value
