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
var _ignored_platforms: Array[PhysicsBody2D] = []
var _knockback_vel_x_add := 0.
var _curr_dir: Lib.Direction

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
@export var melee_damage := 50.
@export var ranged_damage := 33.
@export var melee_weapon: MeleeWeapon

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
	%BodyCollision.disabled = true
	_alive = false


func get_dir() -> Lib.Direction:
	return _curr_dir

func hit(damage: float, knockback: float, from: Vector2):
	hp -= damage
	var knockback_dir = Vector2(
		sign(global_position.x - from.x) * 2, -1.
	).normalized()
	var total_knockback: Vector2 = knockback_dir * knockback
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
		%PlayerSprite.scale.x = axis_x
		_curr_dir = Lib.Direction.RIGHT if axis_x > 0 else Lib.Direction.LEFT
	
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
			velocity.y = -jump_vel
			%PlayerSprite.start_squish_tween()
	
	#----------------------------
	# Если находимся на земле
	#----------------------------
	elif is_on_floor():
		# Если только что призмелились
		if !_was_on_floor:
			%PlayerSprite.start_squish_tween()
			_clone_particles(landing_particles)
			_was_on_floor = true
		_can_floor_jump = true
		_air_jumps_q = 0
		# Спрыгиваем с платформы. Добавляем все платформы, которых касается игрок,
		# в список исключений на короткое время.
		if Input.is_action_pressed("move_down"):
			for i in get_slide_collision_count():
				var collider: Object = get_slide_collision(i).get_collider()
				if collider.is_in_group("platform"):
					add_collision_exception_with(collider)
					_ignored_platforms.append(collider)
			if !_ignored_platforms.is_empty():
				get_tree().create_timer(0.05).timeout.connect(_clear_platform_exceptions)
	
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


func _clone_particles(particles: DisposableParticles, deleting_time := 4.0):
	var cloned_p = particles.duplicate()
	%Particles.add_child(cloned_p)
	cloned_p.start()


func _clear_platform_exceptions():
	for platform in _ignored_platforms:
		remove_collision_exception_with(platform)
		_ignored_platforms.erase(platform)


func _on_air_state_delay_timer_timeout() -> void:
	_can_floor_jump = false
 
