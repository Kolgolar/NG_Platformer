class_name Player
extends CharacterBody2D

signal hp_changed(value: float)

const MAX_MOVE_SPEED: float = 350.
const GRAVITY_VEL: float = 40.
const JUMP_VEL: float = 600.

var hp := 100.:
	set(value):
		hp = value
		hp_changed.emit(hp)
# Истина, если перс на полу или совсем недавно покинул поверхность БЕЗ совершения прыжка. Тем самым
# даём игроку небольшую фору
var _can_floor_jump := false
var _air_jumps_q := 0
var _was_on_floor := false
var _ignored_platforms: Array[PhysicsBody2D] = []

@export_category("Jump")
@export var max_air_jumps_q := 1
@export var air_state_detect_delay: float = 0.2

@export_category("Inercia")
@export var inercia_enabled := false
@export var inertia_accel := 400.0

@export_category("Particles")
@export var landing_particles: GPUParticles2D

@export_category("Combat")
@export var max_hp := 100.
@export var melee_damage := 50.
@export var ranged_damage := 33.


func _ready() -> void:
	
	await get_tree().process_frame
	hp = hp


func _physics_process(delta: float) -> void:
	_movement(delta)


func _movement(delta: float) -> void:
	#----------------------------
	# Движение по горизонтали
	#----------------------------
	var axis_x = Input.get_axis("move_left", "move_right")
	if inercia_enabled:
		velocity.x = lerp(velocity.x, MAX_MOVE_SPEED * axis_x, 30.0 * delta)
	else:
		velocity.x = axis_x * MAX_MOVE_SPEED
	if axis_x != 0:
		%PlayerSprite.scale.x = axis_x
	
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
			velocity.y = -JUMP_VEL
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
	
	velocity.y += GRAVITY_VEL
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
