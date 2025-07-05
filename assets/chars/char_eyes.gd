extends Sprite2D

const MAX_GLAZE_SHIFTS = Vector2(2, 1)

@export_category("Blink")
@export var min_opened_time := 0.5
@export var max_opened_time := 4.5
@export var min_blink_time := 0.08
@export var max_blink_time := 0.15

@export_category("Glaze")
@export var min_glaze_time := 0.3
@export var max_glaze_time = 4.

var _is_blinking := true

var _blink_timer: Timer
var _glaze_timer: Timer

func _ready() -> void:
	_blink_timer = Timer.new()
	add_child(_blink_timer)
	_blink_timer.timeout.connect(_change_blink_state)
	_change_blink_state()
	
	_glaze_timer = Timer.new()
	add_child(_glaze_timer)
	_glaze_timer.timeout.connect(_change_glaze_state)
	_change_glaze_state()


func enable_glazing(enable: bool) -> void:
	if enable:
		_glaze_timer.start()
	else:
		_glaze_timer.stop()
		position *= 0


func _change_blink_state() -> void:
	_is_blinking = !_is_blinking
	visible = !_is_blinking
	var time = randf_range(min_blink_time, max_blink_time) if _is_blinking\
	else randf_range(min_opened_time, max_opened_time)
	_blink_timer.start(time)


func _change_glaze_state() -> void:
	position = Vector2(
		randf_range(-MAX_GLAZE_SHIFTS.x, MAX_GLAZE_SHIFTS.x),
		randf_range(-MAX_GLAZE_SHIFTS.y, MAX_GLAZE_SHIFTS.y)
	)
	_glaze_timer.start(randf_range(min_glaze_time, max_glaze_time))
