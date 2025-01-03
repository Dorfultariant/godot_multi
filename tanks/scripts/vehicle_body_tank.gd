extends VehicleBody3D

var LeftTrackWheels : Array = []
var RightTrackWheels : Array = []

## Export variables (GUI configurable)
@export_category("Player speed")
@export_range(1, 5) var tank_gears : int = 3 # How many gears to simulate
@export_range(100, 10000.0) var speed_forward : float = 2500.0
@export_range(100, 10000.0) var speed_backward : float = 2000.0
@export_range(0.1, 100.0) var speed_turn_max : float = 90
@export_range(0.1, 100.0) var speed_turn_min : float = 15
@export_range(1.0, 10.0) var turbo_speed_mult : float = 1.5
@export_range(0.1, 100.0) var speed_on_air : float = 0.0
@export_range(0.1, 100.0) var acceleration : float = 1.2
@export_range(0.1, 100.0) var acceleration_air : float = 1.0
@export_range(0.1, 100.0) var deacceleration : float = 2.0

var spring_max_force : float = get_mass() * 2
var spring_stiffness : float = 10.0
var spring_damping_compression = 0.5
var spring_damping_relaxation = 1.0
var spring_travel : float = 0.30
var spring_rest_length : float = 0.15

## OnReady variables
@onready var turret = $Turret
@onready var ground_detect_ray = $FlipRay
var rocket_instance
#@onready var ground_back_ray = $GroundBackRay

## Internal variables
var turbo_enabled : bool = false
var keep_turret_fixed : bool = false

var max_velocity : float = 0.0

# Animation
#@onready var anim = $AnimationPlayer

func _ready() -> void:
	add_collision_exception_with(turret)
	ground_detect_ray.add_exception(turret)
	for node in get_children():
		if node.get_class() == "VehicleWheel3D":
			if sign(node.transform.origin.x) > 0:
				LeftTrackWheels.append(node)
			else:
				RightTrackWheels.append(node)
	print("Found %d tracks connected to vehicle." % [LeftTrackWheels.size()+RightTrackWheels.size()])
	
	# Setup wheels
	for wheel in LeftTrackWheels:
		if wheel.name == "LFWheel" || wheel.name == "LRWheel":
			wheel.suspension_stiffness = spring_stiffness * 2.5
			wheel.suspension_max_force = spring_max_force * 3.0
			wheel.use_as_steering = true
			wheel.use_as_traction = true
			wheel.damping_compression = spring_damping_compression
			wheel.damping_relaxation = spring_damping_relaxation
			wheel.wheel_friction_slip = 1
			wheel.suspension_travel = spring_travel
			wheel.wheel_rest_length = spring_rest_length
			wheel.wheel_roll_influence = 0.95
		else:
			wheel.suspension_stiffness = spring_stiffness
			wheel.suspension_max_force = spring_max_force
			wheel.use_as_steering = true
			wheel.use_as_traction = true
			wheel.damping_compression = spring_damping_compression
			wheel.damping_relaxation = spring_damping_relaxation
			wheel.wheel_friction_slip = 1
			wheel.suspension_travel = spring_travel
			wheel.wheel_rest_length = spring_rest_length
			wheel.wheel_roll_influence = 0.95
	
	for wheel in RightTrackWheels:
		if wheel.name == "RFWheel" || wheel.name == "RRWheel":
			wheel.suspension_stiffness = spring_stiffness * 2.5
			wheel.suspension_max_force = spring_max_force * 3.0
			wheel.use_as_steering = true
			wheel.use_as_traction = true
			wheel.damping_compression = spring_damping_compression
			wheel.damping_relaxation = spring_damping_relaxation
			wheel.wheel_friction_slip = 1
		else:
			wheel.suspension_stiffness = spring_stiffness
			wheel.suspension_max_force = spring_max_force
			wheel.use_as_steering = true
			wheel.use_as_traction = true
			wheel.damping_compression = spring_damping_compression
			wheel.damping_relaxation = spring_damping_relaxation
			wheel.wheel_friction_slip = 1

func _physics_process(delta: float) -> void:
	# Turbo
	if Input.is_action_pressed("player_turbo"):
		turbo_enabled = true
	else:
		turbo_enabled = false
	if Input.is_action_just_released("player_reload"):
		if ground_detect_ray.is_colliding():
			var rot_not_y = rotation.normalized()
			rot_not_y.y = 0.0
			apply_torque_impulse(-75000.0 * rot_not_y)
	# Movement
	#var input_dir : Vector2 = Vector2.ZERO # Used only for UP and DOWN (can be replaced with single int 
	var input_movement : float = Input.get_axis("player_backward", "player_forward") # Strength might be useful too
	var input_steering : float = Input.get_axis("player_turn_left", "player_turn_right") # Here as well
	#var velocity : float = 
	if Input.is_action_pressed("player_forward"):
		for wheel in LeftTrackWheels:
			if turbo_enabled:
				wheel.engine_force = speed_forward * 1.3
			else:
				wheel.engine_force = speed_forward
			wheel.brake = 0.0
		for wheel in RightTrackWheels:
			if turbo_enabled:
				wheel.engine_force = speed_forward * 1.3
			else:
				wheel.engine_force = speed_forward
			wheel.brake = 0.0
	elif Input.is_action_pressed("player_backward"):
		for wheel in LeftTrackWheels:
			wheel.engine_force = -speed_backward
			wheel.brake = 0.0
		for wheel in RightTrackWheels:
			wheel.engine_force = -speed_backward
			wheel.brake = 0.0
	else: # Brake
		for wheel in LeftTrackWheels:
			wheel.engine_force = 0.0
			# Front and Rear wheels should have less brake power
			if wheel.name == "LFWheel" || wheel.name == "LRWheel":
				wheel.brake = lerp(wheel.brake, 0.2*speed_backward, delta * deacceleration)
			else:
				wheel.brake = lerp(wheel.brake, 0.2*speed_backward, delta * deacceleration)
		for wheel in RightTrackWheels:
			wheel.engine_force = 0.0
			# Front and Rear wheels should have less brake power
			if wheel.name == "RFWheel" || wheel.name == "RRWheel":
				wheel.brake = lerp(wheel.brake, 0.2*speed_backward, delta * deacceleration) 
			else:
				wheel.brake = lerp(wheel.brake, 0.2*speed_backward, delta * deacceleration)
	
	if Input.is_action_pressed("player_turn_left"):
		for wheel in LeftTrackWheels:
			wheel.engine_force = -10 * speed_forward
		for wheel in RightTrackWheels:
			wheel.engine_force = 10 * speed_forward
		
	elif Input.is_action_pressed("player_turn_right"):
		for wheel in LeftTrackWheels:
			wheel.engine_force = 10 * speed_forward
		for wheel in RightTrackWheels:
			wheel.engine_force = -10 * speed_forward
