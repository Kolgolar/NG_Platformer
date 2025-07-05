class_name MeleeWeapon
extends Node2D


func _ready() -> void:
	hide()


func attack(side: Lib.Direction):
	show()
	var anim_name = "attack_"
	match side:
		Lib.Direction.LEFT:
			anim_name += "left"
		Lib.Direction.RIGHT:
			anim_name += "right"
	$Pivot/AnimationPlayer.play(anim_name)
