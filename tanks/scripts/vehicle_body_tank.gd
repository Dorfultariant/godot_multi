extends VehicleBody3D

var LeftTrackWheels : Array = []
var RightTrackWheels : Array = []

## Export variables (GUI configurable)
@export_category("Vehicle movement")
@export_range(100, 10000.0) var max_engine_power : float = 8000.0
@export var power_curve : Curve = null
@export_range(100, 10000.0) var brake_power : float = 1000.0
@export_range(0.1, 5000.0) var turn_power_min : float = 2000.0
@export_range(0.1, 5000.0) var turn_power_max : float = 4000.0
@export var turn_power_curve : Curve = null
@export_range(1.0, 5.0) var turbo_speed_mult : float = 1.5
@export_range(0.1, 5.0) var acceleration : float = 1.2
@export_range(0.1, 5.0) var deacceleration : float = 1.5

@onready var last_pos = position

var input_movement : float = 0.0
var input_steering : float = 0.0

var spring_max_force : float = get_mass() * 10.5
var spring_stiffness : float = 10.5
var spring_damping_compression = 0.95
var spring_damping_relaxation = 0.995
var spring_travel : float = 0.30
var spring_rest_length : float = 0.1
var wheel_friction = 0.975
var wheel_number : int = 0
## OnReady variables
@onready var turret = $Turret
@onready var ground_detect_ray = $FlipRay
@onready var wmanager = $WeaponManager
var rocket_instance
#@onready var ground_back_ray = $GroundBackRay

## Internal variables
var turbo_enabled : bool = false
var keep_turret_fixed : bool = false
var max_velocity : float = 40 # kmh
var velocity : float
#var last_pos : Vector3 = position
var player_in_control = true

# Animation
#@onready var anim = $AnimationPlayer
var msg_num : int = 0

func calculate_engine_force(normalized_vel) -> float:
	msg_num += 1
	if msg_num == 60:
		msg_num = 0
		print("Velocity ", snapped(velocity, 0.1), " - Normalized Vel: ", snapped(normalized_vel, 0.01), " - Calculated force: ", round(max_engine_power * power_curve.sample_baked(normalized_vel)))
	return max_engine_power * power_curve.sample_baked(normalized_vel)
	

func _ready() -> void:
	# Collision expection with turret (otherwise it won't move)
	add_collision_exception_with(turret)
	# Set the player bodies to Global variable
	Global.player_body = [self, turret]
	ground_detect_ray.add_exception(turret)
	for node in get_children():
		if node.get_class() == "VehicleWheel3D":
			if sign(node.transform.origin.x) > 0:
				LeftTrackWheels.append(node)
			else:
				RightTrackWheels.append(node)
	wheel_number = LeftTrackWheels.size()
	print("Found %d tracks connected to vehicle." % [LeftTrackWheels.size()+RightTrackWheels.size()])
	
	# Setup wheels
	for wheel in LeftTrackWheels:
		wheel.suspension_stiffness = spring_stiffness
		wheel.suspension_max_force = spring_max_force
		wheel.use_as_steering = true
		wheel.use_as_traction = true
		wheel.damping_compression = spring_damping_compression
		wheel.damping_relaxation = spring_damping_relaxation
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_travel = spring_travel
		wheel.wheel_rest_length = spring_rest_length
		wheel.wheel_roll_influence = 0.95
		if wheel.name == "LFWheel":# || wheel.name == "LRWheel":
			wheel.suspension_stiffness = spring_stiffness * 2.5
			wheel.suspension_max_force = spring_max_force * 3.0
			wheel.suspension_travel = 0.01#spring_travel/3.0
			wheel.wheel_rest_length = 0.01#spring_rest_length/3.0
	# Setup right side wheels
	for wheel in RightTrackWheels:
		wheel.suspension_stiffness = spring_stiffness
		wheel.suspension_max_force = spring_max_force
		wheel.use_as_traction = true
		wheel.damping_compression = spring_damping_compression
		wheel.damping_relaxation = spring_damping_relaxation
		wheel.wheel_friction_slip = wheel_friction
		wheel.suspension_travel = spring_travel
		wheel.wheel_rest_length = spring_rest_length
		wheel.wheel_roll_influence = 0.95
		# update specific wheels (front in this case)
		if wheel.name == "RFWheel":# || wheel.name == "RRWheel":
			wheel.suspension_stiffness = spring_stiffness * 2.5
			wheel.suspension_max_force = spring_max_force * 3.0
			wheel.suspension_travel = 0.01 #spring_travel / 3.0
			wheel.wheel_rest_length = 0.01 #spring_rest_length / 3.0
			
	# Set Weapon manager
	wmanager.Initialize()

func _input(event: InputEvent) -> void:
	if event.is_action_released("player_reload"): #is_action_just_released("player_reload"):
		if ground_detect_ray.is_colliding():
			var rot_not_y = rotation.normalized()
			rot_not_y.y = 0.0
			apply_torque_impulse(-75000.0 * rot_not_y)

func _physics_process(delta: float) -> void:
	# Turbo
	if player_in_control and Input.is_action_pressed("player_turbo"):
		turbo_enabled = true
	else:
		turbo_enabled = false
	# Movement
	input_movement = Input.get_axis("player_backward", "player_forward") # Strength might be useful too
	input_steering = Input.get_axis("player_turn_left", "player_turn_right") # Here as well
	var eng_force : float = 0.0
	var turn_influence : float = 0.0
	velocity = (position - last_pos).length() / delta
	if player_in_control and (input_movement != 0.0 || input_steering != 0.0):
		var normalized_vel = clamp(velocity/max_velocity, 0.0, 1.0)
		eng_force = calculate_engine_force(normalized_vel)
		turn_influence = turn_power_curve.sample_baked(normalized_vel) #clamp(velocity/turn_power_max, turn_power_min, turn_power_max) 
	if player_in_control and input_movement != 0.0:#Input.is_action_pressed("player_forward"):
		brake = 0.0
		engine_force = eng_force * input_movement #speed_forward
		if turbo_enabled:
			engine_force *= turbo_speed_mult #speed_forward * 1.3
	else: #elif not braking_done: # Brake
		engine_force = 0.0
		brake = clamp(1.0 * brake_power / 2.0*velocity, 0.0, brake_power) # might need divide by zero check
	if player_in_control and input_movement < 0.0 and input_steering != 0.0:#Input.is_action_pressed("player_turn_left"):
		#brake = 0.0
		var left_pwr = -input_steering * turn_power_max * turn_influence #clamp(-input_steering * turn_power_max * turn_influence, -input_steering * turn_power_max, -input_steering * turn_power_max)
		var right_pwr = input_steering * turn_power_max * turn_influence #clamp(input_steering * turn_power_max * turn_influence, input_steering * turn_power_max, input_steering * turn_power_max)
		#print("Left: ", left_pwr, ", Right: ", right_pwr)
		for wheel_idx in wheel_number:
			LeftTrackWheels[wheel_idx].engine_force = left_pwr
			RightTrackWheels[wheel_idx].engine_force = right_pwr
	# Add and elif here to backward motion and steering like:
	elif player_in_control and input_steering != 0.0:
		#brake = 0.0
		var left_pwr = input_steering * turn_power_max * turn_influence #clamp(input_steering * turn_power_max * turn_influence, input_steering * turn_power_max, input_steering * turn_power_max)
		var right_pwr = -input_steering * turn_power_max * turn_influence #clamp(-input_steering * turn_power_max * turn_influence, -input_steering * turn_power_max, -input_steering * turn_power_max)
		#print("Left: ", left_pwr, ", Right: ", right_pwr)
		for wheel_idx in wheel_number:
			LeftTrackWheels[wheel_idx].engine_force = left_pwr
			RightTrackWheels[wheel_idx].engine_force = right_pwr
	last_pos = position
func player_make_current() -> void:
	player_in_control = true
	turret.player_make_current()

func player_elsewhere() -> void:
	player_in_control = false
	turret.player_elsewhere()
