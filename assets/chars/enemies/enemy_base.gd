class_name Enemy
extends CharacterBody2D

signal max_hp_changed(value: float)
signal hp_changed(value: float)
signal dead

#enum MoveDirection {RIGHT = -1, NONE = 0, LEFT = 1}
enum State {NONE, PATROLING, CHASING}

var _target_speed_x := 0.
var _is_freezed_by_attacking := false
var _is_closely_to_player := false
var _is_stunned := false

var _targets_to_hit := []

@export_category("Movement")
@export var patroling_speed: float = 100.
@export var chasing_speed: float = 350.
@export var gravity_vel: float = 1200.
@export var knockback_damp := 10.

@export_category("Combat")
@export var can_attack := true
@export var max_hp := 20.:
	set(value):
		max_hp = value
		max_hp_changed.emit(value)
@export var touch_attack_params: AttackParams
@export var hit_reaction_time := 0.33
@export var attack_freezing_time := 0.2

@onready var hp: float = max_hp:
	set(value):
		hp = value
		hp_changed.emit(hp)
		if hp <= 0:
			death()

@onready var _curr_move_dir := Lib.Direction.NONE:
	set(value):
		_curr_move_dir = value
		_update_move_dir_dependencies()
		
@onready var _curr_state := State.PATROLING:
	set(value):
		_curr_state = value
		_update_state_dependencies()


func _ready() -> void:
	%PlayerDetectedSign.hide()
	_curr_move_dir = Lib.Direction.RIGHT if randi() % 2 == 0 else Lib.Direction.LEFT
	_update_state_dependencies()
	await get_tree().process_frame
	max_hp = max_hp
	hp = hp
	if can_attack:
		%AttackTicker.start()
	

func _physics_process(delta: float) -> void:
	_raycast_processing()
	_movement(delta)


func hit(attack_params: AttackParams, from: Vector2):
	hp -= attack_params.damage
	var knockback_dir = Vector2(
		sign(global_position.x - from.x) * 2, -1.
	).normalized()
	var total_knockback: Vector2 = knockback_dir * attack_params.knockback
	if total_knockback != Vector2.ZERO:
		velocity = total_knockback
	if attack_params.stun_time > 0:
		_is_stunned = true
		%StunTimer.start(attack_params.stun_time)
	
	await get_tree().create_timer(hit_reaction_time).timeout
	_search_at(from)


func death():
	dead.emit()
	queue_free()


func _raycast_processing():
	#------------------
	# Необходимо ли поменять направление движения
	#------------------
	var floor_collider = %PitRayCast.get_collider()
	if !floor_collider && is_on_floor():
		_change_move_dir()
		
	_is_closely_to_player = false
	var wall_collider = %WallRayCast.get_collider()
	if wall_collider:
		if wall_collider is Player:
			_is_closely_to_player = true
		else:
			_change_move_dir()


func _movement(delta: float) -> void:
	if _is_stunned:
		velocity = lerp(velocity, Vector2.ZERO, knockback_damp * delta)
	elif _is_freezed_by_attacking || _is_closely_to_player:
		velocity.x = 0.
	else:
		velocity.x = _target_speed_x * _curr_move_dir
	velocity.y += gravity_vel * delta
	move_and_slide()


func _change_move_dir():
	_curr_move_dir *= -1


func _update_move_dir_dependencies():
	%EnemySprite.look_to(_curr_move_dir)
	%RayCasts.scale.x = _curr_move_dir
	%DetectionArea.scale.x = _curr_move_dir


func _update_state_dependencies():
	%PlayerDetectedSign.visible = _curr_state == State.CHASING
	match _curr_state:
		State.NONE:
			_target_speed_x = 0.
		State.CHASING:
			_target_speed_x = chasing_speed
		State.PATROLING:
			_target_speed_x = patroling_speed


func _attack_targets_to_hit():
	if _is_freezed_by_attacking || !%AttackTimeout.is_stopped(): return
	for targ in _targets_to_hit:
		if targ is Player:
			(targ as Player).hit(touch_attack_params, global_position)
			%AttackTimeout.start()
			_is_freezed_by_attacking = true
			await get_tree().create_timer(attack_freezing_time).timeout
			_is_freezed_by_attacking = false


func _search_at(pos: Vector2):
	var diff = sign(pos.x - global_position.x)
	_curr_move_dir = Lib.Direction.LEFT if diff < 0 else Lib.Direction.RIGHT


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_search_at(body.global_position)
		set_deferred("_curr_state", State.CHASING)
		

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player:
		set_deferred("_curr_state", State.PATROLING)


func _on_attack_area_body_entered(body: Node2D) -> void:
	_targets_to_hit.append(body)


func _on_attack_area_body_exited(body: Node2D) -> void:
	_targets_to_hit.erase(body)


func _on_attack_ticker_timeout() -> void:
	_attack_targets_to_hit()


func _on_stun_timer_timeout() -> void:
	_is_stunned = false


func _on_dir_change_timer_timeout() -> void:
	pass # Replace with function body.
