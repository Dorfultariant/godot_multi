extends RigidBody3D

## Export variables (GUI configurable)
@export_category("Player speed")
@export_range(1, 5) var tank_gears : int = 3 # How many gears to simulate
@export_range(0.1, 100.0) var speed_forward : float = 4.0
@export_range(0.1, 100.0) var speed_backward : float = 2.0
@export_range(0.1, 100.0) var speed_turn_max : float = 90
@export_range(0.1, 100.0) var speed_turn_min : float = 15
@export_range(1.0, 10.0) var turbo_speed_mult : float = 1.5
@export_range(0.1, 100.0) var speed_on_air : float = 0.0
@export_range(0.1, 100.0) var acceleration : float = 1.2
@export_range(0.1, 100.0) var acceleration_air : float = 1.0
@export_range(0.1, 100.0) var deacceleration : float = 2.0

## OnReady variables
@onready var turret = $Turret
#@onready var ground_front_ray = $GroundFrontRay
#@onready var ground_back_ray = $GroundBackRay

## Internal variables
var millis = 0
var impulse_on_bodies : float = 1000.0
var turbo_enabled : bool = false
var keep_turret_fixed : bool = false

var max_velocity : float = 0
var a : float = 0 # Amplitude
var c : float = 0 # Mid point for turning max - min
var b : float = 0 # Period


# Animation
@onready var anim = $AnimationPlayer

func _ready() -> void:
	# Max velocity approximation
	max_velocity = speed_forward * 1.0
	a = (speed_turn_max - speed_turn_min) / 2 # Amplitude
	b = 2 * max_velocity # At half period we are in low position, thus period needs to be twice our target max velocity
	c = a + speed_turn_min # Our minimum turn speed when at max velocity.
	#print("MaxVel: ", max_velocity)
	#print("A: ", a)
	#print("B: ", b)
	#print("C: ", c)
	
	# From turret, when player fires there, we play tank's firing animation here.
	#turret.connect("player_fires", _on_player_fires) 

func turn_speed_at_velocity(velocity_length: float) -> float:
	# Follows function: a cos(2pi*velocity_length / b) + c
	# Set the a, b and c first
	#if velocity_length >= c:
		#return speed_turn_min
	#elif velocity_length <= 0.1:
		#return speed_turn_max
	#else:
		#
	var new_turn_speed = a * cos((2 * PI * velocity_length) / (b)) + c
	#print(new_turn_speed)
	return clamp(new_turn_speed, speed_turn_min, speed_turn_max)

func _physics_process(delta: float) -> void:
	#add_constant_torque(Vector3(0,0,0))
	#if not is_on_floor():
		#velocity += Global.generalGravity * Vector3.DOWN * delta;
	#
	
	# Turbo
	if Input.is_action_pressed("player_turbo"):
		turbo_enabled = true
	else:
		turbo_enabled = false
	
	# Movement
	var input_dir : Vector2 = Vector2.ZERO # Used only for UP and DOWN (can be replaced with single int 
	if Input.is_action_pressed("player_forward"):
		input_dir = Vector2.UP
	if Input.is_action_pressed("player_backward"):
		input_dir = Vector2.DOWN
	if Input.is_action_pressed("player_turn_left"):
		apply_torque_impulse(Vector3(0,10,0))
		#var turn_speed : float = turn_speed_at_velocity(velocity.length())
		#turn_speed = deg_to_rad(turn_speed)
		#print(velocity.length())
		#print(turn_speed)
		#print("Delta: ", delta)
		
		#rotation.y += turn_speed * delta #rotation.y += -input_dir.y * turn_speed * delta
		
		# Keep turret from rotating
		#if not keep_turret_fixed:
			#turret.rotation.y -= -input_dir.y * turn_speed*delta
		#	turret.rotation.y -= turn_speed * delta
	if Input.is_action_pressed("player_turn_right"):
		apply_torque_impulse(Vector3(0,-10,0))
		#var turn_speed : float = turn_speed_at_velocity(velocity.length())
		#turn_speed = deg_to_rad(turn_speed)
		##print(velocity.length())
		##print(turn_speed)
		##rotation.y -= -input_dir.y * turn_speed * delta
		#rotation.y -= turn_speed * delta
		## Keep turret from rotating
		#if not keep_turret_fixed:
			##turret.rotation.y += -input_dir.y * turn_speed * delta
			#turret.rotation.y += turn_speed * delta
		
	var direction : Vector3
	if turbo_enabled:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#
	## Velocity on direction
	#if direction:
		#if turbo_enabled:
			#velocity.x = lerp(velocity.x, direction.x * turbo_speed_mult * speed_forward, acceleration * delta)
			#velocity.z = lerp(velocity.z, direction.z * turbo_speed_mult * speed_forward, acceleration * delta)
		#else:
			#velocity.x = lerp(velocity.x, direction.x * speed_forward, acceleration * delta)
			#velocity.z = lerp(velocity.z, direction.z * speed_forward, acceleration * delta)
	#
	#else:
		#velocity.x = lerp(velocity.x, 0.0, deacceleration * delta)
		#velocity.z = lerp(velocity.z, 0.0, deacceleration * delta)
		
	# Move 
	#move_and_slide()
	#point_to_ground(delta)
	# Lastly add some pushing forces for the RigidBodies
	#push_pushables(delta)
#
#func point_to_ground(delta: float) -> void:
	#var n = (ground_front_ray.get_collision_normal() + ground_back_ray.get_collision_normal()) / 2.0
	#var xform = align_with_y(global_transform, n)
	#global_transform = global_transform.interpolate_with(xform, 12.0 * delta).orthonormalized()

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform.orthonormalized()

#func push_pushables(delta: float) -> void:
	#var col := get_last_slide_collision()
#
	#if col:
		#var col_collider := col.get_collider()
		#var col_position := col.get_position()
#
		#if not col_collider is RigidBody3D:
			#return
		#
		#var push_direction := -col.get_normal()
		#var push_position = col_position - col_collider.global_position
		#col_collider.apply_impulse(push_direction * impulse_on_bodies * delta, push_position)
		#print("Applied ", push_direction * 500 * delta, " impulse for ", col_collider)

#func _on_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "idle_run":
		#anim.play("idle_run") # Loop
	#elif anim_name == "fire":
		#anim.play("idle_run")
#
#func _on_player_fires() -> void:
	#anim.play("fire")
