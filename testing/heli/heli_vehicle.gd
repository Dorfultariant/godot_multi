extends RigidBody3D

var lift_speed = 40.0
var turn_speed = 5.0
var input_movement : float = 0.0
var input_straffe : float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lift_speed *= mass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_forward", true):
		input_movement = 1.0
	elif event.is_action_pressed("player_backward", true):
		input_movement = -1.0
	else:
		input_movement = 0.0
	
	if event.is_action_pressed("player_turn_left", true):
		input_straffe = 1.0
	elif event.is_action_pressed("player_turn_right", true):
		input_straffe = -1.0
	else:
		input_straffe = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _physics_process(delta: float) -> void:
		if input_movement != 0.0:
			apply_central_impulse(transform.basis * Vector3.UP * delta * lift_speed)
		if input_straffe != 0.0:
			apply_torque_impulse(input_straffe * turn_speed * Vector3.UP)
