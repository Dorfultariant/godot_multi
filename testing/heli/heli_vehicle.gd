extends RigidBody3D

var lift_speed : float = 40.0
var lift_hold_speed : float = 5.0
var yaw_speed : float = 50.2
var roll_speed : float = 50.2
var pitch_speed : float = 15.0
var input_movement : float = 0.0
var input_straffe : float = 0.0

var upwards_force : Vector3
#@export var force_curve : Curve

# This is the force given by player
var engine_force : float = 0.0

# Amount of rotation
var target_rotation : Vector3

var yaw : Vector3 = Vector3(1,0,0)
var pitch : Vector3 = Vector3(0,1,0)
var roll :  Vector3 = Vector3(0,0,1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	lift_speed *= mass
	target_rotation = global_rotation

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		# Mouse controls roll and yaw
		target_rotation.z = event.relative.x / Global.mouseXSensibility # Roll
		target_rotation.x = -event.relative.y / Global.mouseYSensibility # Yaw
		return
	
	if event.is_action_pressed("player_forward", true):
		input_movement = 1.0
		return
	elif event.is_action_released("player_forward"):
		input_movement = 0.0
	elif event.is_action_pressed("player_backward", true):
		input_movement = -1.0
		return
	elif event.is_action_released("player_backward"):
		input_movement = 0.0
		return
	
	if event.is_action_pressed("player_turn_left", true):
		input_straffe = 1.0
	elif event.is_action_released("player_turn_left"):
		input_straffe = 0.0
	elif event.is_action_pressed("player_turn_right", true):
		input_straffe = -1.0
	elif event.is_action_released("player_turn_right"):
		input_straffe = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	transform = transform.orthonormalized()

func _physics_process(delta: float) -> void:
	# Engine force
	if input_movement != 0.0:
		engine_force = lerp(engine_force, lift_speed, 2.0 * input_movement * delta)
	else:
		engine_force = lerp(engine_force, 0.0, 15.0 * delta)
	if input_straffe != 0.0:
		apply_torque_impulse(input_straffe * 4.0 * pitch_speed * pitch)
	
	if input_movement != 0.0:
		add_constant_force(transform.basis * Vector3.UP * delta * engine_force)
	else:
		constant_force = lerp(constant_force, lift_hold_speed * Vector3(0,1.0,0), 15.0 * delta)
	
	apply_torque_impulse(target_rotation.z * 100.0 * roll_speed * transform.basis.z)
	apply_torque_impulse(target_rotation.x * 100.0 * yaw_speed * transform.basis.x)
	#transform.basis = Basis()
	#rotate(roll, target_rotation.z)
	#rotate(yaw, target_rotation.x)
	
	#global_rotation.x = lerp_angle(rotation.x, target_rotation.x, yaw_speed * delta)
	#global_rotation.y = lerp_angle(rotation.y, target_rotation.y, turn_speed * delta)
	#global_rotation.z = lerp_angle(rotation.z, target_rotation.z, roll_speed * delta)
	#apply_force(transform.basis * Vector3.UP * delta * engine_force) #apply_force_impulse(transform.basis * Vector3.UP * delta * lift_speed)
