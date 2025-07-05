extends Sprite2D

const SQUISHING_TIME: float = 0.2
const SQUISHING_MULT: float = 0.15
const DEFAULT_HEIGHT: float = 64.

@onready var _default_scale = scale


func start_squish_tween():
	create_tween().tween_method(_squishing, 0., 1., SQUISHING_TIME)
	

func look_to(dir: Lib.Direction):
	scale.x = dir * _default_scale.x


func _squishing(value: float):
	var mult = sin(value * PI) * SQUISHING_MULT
	#print(mult)
	%PlayerSprite.scale.y = (1 - mult) * _default_scale.y
	%PlayerSprite.position.y = DEFAULT_HEIGHT * mult / 2
