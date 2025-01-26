extends RigidBody3D

@export var lift_speed : float = 20.0
@export var hover_speed : float = 10.0
@export var lift_hold_speed : float = 5.0
@export var yaw_speed : float = 50.2
@export var roll_speed : float = 50.2
@export var pitch_speed : float = 15.0

var input_movement : float = 0.0
var input_straffe : float = 0.0
var input_turned : bool = false

var thrust_value : float = 0.0
var lift_value : float = 0.0
#@export var force_curve : Curve

# This is the force given by player
var engine_force : float = 0.0

# Amount of rotation
var target_rotation : Vector3
var last_target_rotation : Vector3

var yaw : Vector3 = Vector3(1,0,0)
var pitch : Vector3 = Vector3(0,1,0)
var roll :  Vector3 = Vector3(0,0,1)

@export var engine_path : NodePath

var player_in_control : bool = true

@onready var fp_cam : Camera3D = $CameraFP
@onready var tp_cam : Camera3D = $SpringArm3D/Camera3P
var current_camera : Camera3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.player_body = [self, null]
	
	current_camera = fp_cam
	current_camera.make_current()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	target_rotation = global_rotation

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player_in_control and event.is_action_released("player_toggle_camera"):
		if fp_cam.current:
			fp_cam.current = false
			tp_cam.current = true
			current_camera = tp_cam
			
		else:
			tp_cam.current = false
			fp_cam.current = true
			current_camera = fp_cam
		return
	if player_in_control and event is InputEventMouseMotion:
		# Mouse controls roll and yaw
		target_rotation.z = event.relative.x / Global.mouseXSensibility # Roll
		target_rotation.x = -event.relative.y / Global.mouseYSensibility # Yaw
		input_turned = true
		return
	else:
		input_turned = false
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	transform = transform.orthonormalized()

func _physics_process(delta: float) -> void:
	input_movement = Input.get_axis("player_backward", "player_forward")
	input_straffe = Input.get_axis("player_turn_right", "player_turn_left")
	if player_in_control and input_movement > 0.0:
		lift_value = lerp(lift_value, lift_speed, 30.0 * delta)
	elif player_in_control and input_movement < 0.0:
		lift_value = lerp(lift_value, 2.0, 15.0 * delta)
	elif !player_in_control:
		lift_value = lerp(lift_value, hover_speed, 10.0 * delta)
	else:
		lift_value = lerp(lift_value, 0.7, 10.0 * delta)
	if player_in_control and input_straffe != 0.0:
		apply_torque_impulse(input_straffe * 4.0 * pitch_speed * pitch)
	
	# Apply force = mass * acceleration with direction
	# Direction (from Basis) *
	# To direction (this could be changed to point more forward)
	# Lift value (basically acceleration)
	# Vehicle mass
	apply_central_force(global_transform.basis * Vector3.UP * lift_value * mass)

	$Propels.rotate_y(lift_value)
	# Roll and yaw controls via torque impulse
	if player_in_control and input_turned:
		apply_torque_impulse(target_rotation.z * 100.0 * roll_speed * global_transform.basis.z)
		apply_torque_impulse(target_rotation.x * 100.0 * yaw_speed * global_transform.basis.x)
	
	$SpringArm3D.rotation.x = angular_velocity.x / 10
	$SpringArm3D.rotation.y = PI + angular_velocity.y / 20
	$SpringArm3D.rotation.z = angular_velocity.z / 10

func player_make_current() -> void:
	player_in_control = true

func player_elsewhere() -> void:
	player_in_control = false
