extends Camera2D

@export var start_pos_at_target := true
@export var target: Node2D


func _ready() -> void:
	if start_pos_at_target && position_smoothing_enabled:
		position_smoothing_enabled = false
		await get_tree().process_frame
		_move_to_target()
		await get_tree().process_frame
		position_smoothing_enabled = true


func _process(delta: float) -> void:
	_move_to_target()


func _move_to_target():
	if target:
		global_position = target.global_position
