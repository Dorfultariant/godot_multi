extends CharacterBody3D

@export_category("Player speed")
@export_range(1, 5) var tank_gears : int = 3 # How many gears to simulate
@export_range(0.1, 100.0) var speed_forward : float = 5.0
@export_range(0.1, 100.0) var speed_backward : float = 2.0
@export_range(0.1, 100.0) var speed_turn_max : float = deg_to_rad(90)
@export_range(0.1, 100.0) var speed_turn_min : float = deg_to_rad(15)
@export_range(0.1, 100.0) var turbo_speed : float = speed_forward * 1.5
@export_range(0.1, 100.0) var speed_on_air : float = 0.0
@export_range(0.1, 100.0) var acceleration : float = 1.2
@export_range(0.1, 100.0) var acceleration_air : float = 1.0
@export_range(0.1, 100.0) var deacceleration : float = acceleration * 4

# Variables
var millis = 0
var turbo_enabled : bool = false
var keep_turret_fixed : bool = false
var a : float = (speed_turn_max - speed_turn_min) / 2 # Amplitude
var c : float = speed_forward**2
var b : float = 2 * c # Period


# On-ready variables
@onready var turret = $Turret
@onready var turret_barrel = $Turret/MeshTurret/MeshTurret_Barrel
@onready var weapon_spawn = $Turret/MeshTurret/MeshTurret_Barrel/Turret_Barrel_Pipe/RoundSpawn
@onready var fp_cam = $"Turret/MeshTurret/MeshTurret_Barrel/1stPersonCam"
@onready var tp_cam = $"Turret/MeshTurret/MeshTurret_Barrel/SpringArm3D/3rdPersonCam"
@onready var fire_decal = $"Turret/MeshTurret/MeshTurret_Barrel/Turret_Barrel_Pipe/fire_decal"
@onready var fire_decal_timer = $"Turret/MeshTurret/MeshTurret_Barrel/Turret_Barrel_Pipe/decal_timer"

# PreLoads
@export var weapon_1 : PackedScene = preload("res://tanks/explosions/tank_round.tscn")


func turn_speed_at_velocity(velocity_length: float) -> float:
	# Follows function: a cos(2pi*velocity_length / b) + c
	# Set the a, b and c first
	if velocity_length >= c:
		return speed_turn_min
	elif velocity_length <= 0.1:
		return speed_turn_max
	else:
		return clamp(a * cos((2 * PI * velocity_length) / (b)) + c, speed_turn_min, speed_turn_max)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fp_cam.current = true
	tp_cam.current = false
	
	fire_decal_timer.timeout.connect(_on_timer_timeout)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		turret.rotation.y -= event.relative.x / Global.mouseXSensibility
		turret_barrel.rotation.x -= -event.relative.y / Global.mouseYSensibility
		turret_barrel.rotation.x = clamp(turret_barrel.rotation.x, deg_to_rad(-50),deg_to_rad(5))
	if event.is_action_released("player_toggle_camera"):
		if fp_cam.current:
			fp_cam.current = false
			tp_cam.current = true
		else:
			tp_cam.current = false
			fp_cam.current = true
	if event.is_action_pressed("player_shoot"):
		# Decal timer
		fire_decal.set_visible(true)
		if fire_decal_timer.is_stopped:
			fire_decal_timer.wait_time = 0.2
			fire_decal_timer.start()
		else:
			fire_decal_timer.wait_time = 0.2
		
		# Instantiate the shot tank round or weapon
		var root_scene = get_tree().get_root()
		var weapon_instance = weapon_1.instantiate()
		weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
		root_scene.add_child(weapon_instance)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += 10.0*Vector3.DOWN * delta;
	
	# Turbo
	if Input.is_action_pressed("player_turbo"):
		turbo_enabled = true
	else:
		turbo_enabled = false
	
	# Movement
	var input_dir : Vector2 = Vector2.ZERO
	if Input.is_action_pressed("player_forward"):
		input_dir = Vector2.UP
	if Input.is_action_pressed("player_backward"):
		input_dir = Vector2.DOWN
	if Input.is_action_pressed("player_turn_left"):
		var turn_speed : float = turn_speed_at_velocity(velocity.length())
		print(turn_speed)
		rotation.y += turn_speed * delta
		if not keep_turret_fixed:
			turret.rotation.y -= turn_speed*delta
		print(velocity.length_squared())
	if Input.is_action_pressed("player_turn_right"):
		var turn_speed : float = turn_speed_at_velocity(velocity.length())
		print(turn_speed)
		rotation.y -= turn_speed * delta
		if not keep_turret_fixed:
			turret.rotation.y += turn_speed*delta
		print(velocity.length_squared())
		
	var direction : Vector3
	if turbo_enabled:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Velocity on direction
	if direction:
		if turbo_enabled:
			velocity.x = lerp(velocity.x, direction.x * turbo_speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * turbo_speed, acceleration * delta)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed_forward, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed_forward, acceleration * delta)
	
	else:
		velocity.x = lerp(velocity.x, 0.0, deacceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, deacceleration * delta)
		
	
	move_and_slide()

func _on_timer_timeout():
	
	fire_decal.set_visible(false)
