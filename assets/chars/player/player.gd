class_name Player
extends CharacterBody2D

signal max_hp_changed(value: float)
signal hp_changed(value: float)
signal dead

var _alive := true
# Истина, если перс на полу или совсем недавно покинул поверхность БЕЗ совершения прыжка. Тем самым
# даём игроку небольшую фору
var _can_floor_jump := false
var _air_jumps_q := 0
var _was_on_floor := false
var _knockback_vel_x_add := 0.
var _curr_dir := Lib.Direction.RIGHT
var _can_bottom_attack := true

@export_category("Movement")
@export var max_move_speed: float = 350.
@export var gravity_vel: float = 2300.
@export var jump_vel: float = 600.
@export var max_air_jumps_q := 1
@export var air_state_detect_delay: float = 0.2
@export var knockback_damp := 10.

@export_category("Particles")
@export var landing_particles: GPUParticles2D

@export_category("Combat")
@export var max_hp := 100.:
	set(value):
		max_hp = value
		max_hp_changed.emit(value)
@export var melee_weapon: MeleeWeapon
@export var bottom_attack: AttackParams

@onready var hp: float = max_hp:
	set(value):
		hp = value
		hp_changed.emit(value)
		if hp <= 0:
			death()


func _ready() -> void:
	await get_tree().process_frame
	max_hp = max_hp
	hp = hp


func _physics_process(delta: float) -> void:
	_movement(delta)
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		melee_weapon.attack(get_dir())


func death():
	hide()
	dead.emit()
	%BodyCollision.set_deferred("disabled", true)
	_alive = false


func get_dir() -> Lib.Direction:
	return _curr_dir

func hit(attack_params: AttackParams, from: Vector2):
	hp -= attack_params.damage
	var knockback_dir = Vector2(
		sign(global_position.x - from.x) * 2, -1.
	).normalized()
	var total_knockback: Vector2 = knockback_dir * attack_params.knockback
	_knockback_vel_x_add += total_knockback.x
	velocity.y = total_knockback.y


func _movement(delta: float) -> void:
	if !_alive: return
	#----------------------------
	# Движение по горизонтали
	#----------------------------
	var axis_x = Input.get_axis("move_left", "move_right")
	_knockback_vel_x_add = lerp(_knockback_vel_x_add, 0., knockback_damp * delta)
	velocity.x = axis_x * max_move_speed + _knockback_vel_x_add
	if axis_x != 0:
		_curr_dir = Lib.Direction.RIGHT if axis_x > 0 else Lib.Direction.LEFT
		%PlayerSprite.look_to(_curr_dir)
	
	#----------------------------
	# Движение по вертикали
	#----------------------------
	# Если прожали прыжок, не важно, в воздухе или на земле
	if Input.is_action_just_pressed("move_jump"):
		var should_jump := false
		if is_on_floor() || _can_floor_jump:
			_can_floor_jump = false
			should_jump = true
			
		elif _air_jumps_q < max_air_jumps_q:
			_air_jumps_q += 1
			should_jump = true
		
		if should_jump:
			_jump()
	
	#----------------------------
	# Если находимся на земле
	#----------------------------
	elif is_on_floor():
		# Если только что призмелились
		if !_was_on_floor:
			%PlayerSprite.start_squish_tween()
			landing_particles.restart()
			landing_particles.emitting = true
			_was_on_floor = true
		_can_floor_jump = true
		_air_jumps_q = 0
	
	#----------------------------
	# Если находимся в воздухе
	#----------------------------
	else:
		_was_on_floor = false
		# Если оказались в воздухе НЕ совершив прыжок
		if _can_floor_jump && %AirStateDelayTimer.is_stopped():
			%AirStateDelayTimer.start(air_state_detect_delay)
	
	velocity.y += gravity_vel * delta
	move_and_slide()


func _jump():
	velocity.y = -jump_vel
	%PlayerSprite.start_squish_tween()


func _clear_platform_exceptions():
	set_collision_mask_value(1, true)
	set_collision_layer_value(1, true)


func pick_up_item(item: Pickable):
	match item.item_data.type:
		Lib.ItemType.HEALTH:
			if max_hp - hp >= 0.01: # Перестраховка от приколов со сравнением float'ов
				hp += item.item_data.health_add
				item.queue_free()


func _on_air_state_delay_timer_timeout() -> void:
	_can_floor_jump = false
 

func _on_trigger_area_area_entered(area: Area2D) -> void:
	if area is Pickable:
		pick_up_item(area)


func _on_bottom_attack_ticker_timeout() -> void:
	if velocity.y < 0: return
	var enemies = %BottomAttackArea.get_overlapping_bodies()
	if enemies.size() == 0: return
	_jump()
	if !_can_bottom_attack: return
	for enemy in enemies:
		enemy.hit(bottom_attack, global_position)
	_can_bottom_attack = false
	%BottomAttackThreshold.start()


func _on_bottom_attack_threshold_timeout() -> void:
	_can_bottom_attack = true
