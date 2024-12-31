extends CharacterBody3D

@export var FORWARD_SPEED : float = 1.4
@export var BACK_SPEED : float = 0.75
@export var ACCELERATION : float = 0.005
@export var TURN_SPEED : float = 0.8
@export var PROJECTILE_SPEED : float = 200
@export var TURRET_SPEED : float = 0.2 
var speed : float = 0.0
var _mouse_pos = Vector2.ZERO
var camera_anglev : float = 0
var ray_target_pos : Vector3 = Vector3.ZERO
var target_pos : Vector3 = Vector3.ZERO
var is_reloaded : bool = 0
@onready var timer_reload = $Reload_timer
@onready var turret = $IFV_tower
@onready var main_gun = $IFV_tower/IFV_main_turret
@onready var cam : Camera3D = $IFV_tower/Camera3D
@onready var third_cam : Camera3D = $IFV_tower/Third_Person_Camera
@onready var ray : RayCast3D = $IFV_tower/IFV_main_turret/Aim_ray
@onready var projectile_spawn : Marker3D = $IFV_tower/IFV_main_turret/Projectile_spawn
@onready var player_ui : Control = $Player_UI
@onready var reticle : CenterContainer = $Player_UI/Reticle
@onready var reload_left : Label = $Player_UI/TimerCenter/Reload_time_left
@onready var ray_projectile : PackedScene = preload("res://tanks/explosions/tank_round.tscn")


func _ready() -> void:
	timer_reload.start()
	reticle.modulate = Color.RED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if Input.is_action_pressed("player_shoot"):
		if is_reloaded:
			fire_tank_round()
	
	reload_left.text = "%.1f" % timer_reload.time_left
	
func _physics_process(delta: float) -> void:
	
	# For rotating to the surface
	
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta
	if is_on_floor():
		#var b_rot = Quaternion(transform.basis.y, get_floor_normal())
		#transform.basis = (Basis((b_rot * basis.get_rotation_quaternion() * delta)))
	#
		var b_rot = Quaternion(transform.basis.y, get_floor_normal())
		transform.basis = transform.basis.slerp(Basis((b_rot * basis.get_rotation_quaternion())), .1)
	
		if Input.is_action_pressed("player_forward"):
			if (abs(speed) < FORWARD_SPEED):
				speed -= (delta + ACCELERATION)
			#translate(Vector3(0,0,speed))
		elif Input.is_action_pressed("player_backward"):
			if (speed < BACK_SPEED):
				speed += (delta + ACCELERATION)
			#translate(Vector3(0,0,speed))
		else:
			if abs(speed) < 0.1:
				speed = 0
			elif speed < 0:
				speed += delta
			elif speed > 0:
				speed -= delta
		if Input.is_action_pressed("player_turn_left"):
			if speed > 0.0:
				rotate_y(-TURN_SPEED * delta);
				turret.rotate_y(TURN_SPEED * delta)
			elif (speed < 0.0):
				rotate_y(TURN_SPEED * delta);
				turret.rotate_y(-TURN_SPEED * delta)
			
		if Input.is_action_pressed("player_turn_right"):
			if speed > 0.0:
				rotate_y(TURN_SPEED * delta);
				turret.rotate_y(-TURN_SPEED * delta)
			elif (speed < 0.0):
				rotate_y(-TURN_SPEED * delta);
				turret.rotate_y(TURN_SPEED * delta)
	
	translate(Vector3(0,0,speed))
	move_and_slide()
		
	if ray.is_colliding():
		ray_target_pos = ray.get_collision_point()
		
	# Doc said so
	transform = transform.orthonormalized()

func _input(event):
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("player_toggle_camera"):
		if cam.is_current():
			third_cam.make_current()
		else:
			cam.make_current()
	#if Input.is_action_just_pressed("fire"):
		
		
	if event.is_action_pressed("player_zoom"):
		if cam.fov == 20:
			cam.fov = 80
			third_cam.fov = 80
			TURRET_SPEED = TURRET_SPEED * 3
		else:
			TURRET_SPEED = TURRET_SPEED / 3
			third_cam.fov = 20
			cam.fov = 20
	
	if event is InputEventMouseMotion:
		turret.rotate_y(deg_to_rad(-event.relative.x * TURRET_SPEED))
		var changev = event.relative.y * TURRET_SPEED
		if camera_anglev + changev > -50 and camera_anglev + changev < 10:
			camera_anglev += changev
			cam.rotate_x(-deg_to_rad(changev))
			third_cam.rotate_x(-deg_to_rad(changev))
			main_gun.rotate_x(-deg_to_rad(changev))

func fire_tank_round():
		is_reloaded = false
		# Instantiate the shot tank round or weapon
		var root_scene = get_tree().get_root()
		var weapon_instance = ray_projectile.instantiate()
		weapon_instance.SPEED *= -1 * 10
		weapon_instance.set_global_transform(projectile_spawn.get_global_transform())
		root_scene.add_child(weapon_instance)
		reticle.modulate = Color.RED
		timer_reload.start()

func fire_raycast() -> void:
	is_reloaded = false
	var projectile = ray_projectile.instantiate()
	projectile.global_transform = projectile_spawn.global_transform
	add_sibling(projectile)

	reticle.modulate = Color.RED
	timer_reload.start()
	
func _on_reload_ready_timeout() -> void:
	is_reloaded = true
	reticle.modulate = Color.WHITE
