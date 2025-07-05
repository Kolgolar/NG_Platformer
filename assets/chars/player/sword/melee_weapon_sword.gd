class_name MeleeWeapon
extends Node2D


var _bodies_was_hit: Array[Node2D] = []

@export var attack_params: AttackParams
@export var attack_area: Area2D


func _ready() -> void:
	hide()
	attack_area.set_deferred("monitoring", false)


func attack(side: Lib.Direction):
	show()
	var anim_name = "attack_"
	match side:
		Lib.Direction.LEFT:
			anim_name += "left"
		Lib.Direction.RIGHT:
			anim_name += "right"
	$Pivot/AnimationPlayer.play(anim_name)
	attack_area.set_deferred("monitoring", true)


func _on_melee_attack_area_body_entered(body: Node2D) -> void:
	if _bodies_was_hit.has(body): return
	if body is Enemy:
		_bodies_was_hit.append(body)
		body.hit(attack_params, global_position)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	attack_area.set_deferred("monitoring", false)
	_bodies_was_hit.clear()
