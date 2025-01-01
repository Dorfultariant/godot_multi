extends CharacterBody3D

# Exports
@export var MAX_FORWARD_SPEED = 5.0
@export var MAX_REVERSE_SPEED = 2.0
@export var ACCELERATION = 1.2
@export var DEACCELERATION = 0.9
@export var NORMAL_FOV : int = 75
# Constants:
const ZOOM_FOV : int = 20
const MAIN_GUN_MAX_RAISE_ANGLE : float = 50.0
const MAIN_GUN_MAX_LOWER_ANGLE : float = -10.0
# Onreadys:
@onready var first_person_cam : Camera3D = $IFV_tower/First_cam
@onready var third_person_cam : Camera3D = $IFV_tower/Third_cam
@onready var tower : Node3D = $IFV_tower
@onready var main_gun : Node3D = $IFV_tower/IFV_main_turret
@onready var projectile_spawn_marker : Marker3D = $IFV_tower/IFV_main_turret/Projectile_spawn
@onready var aiming_ray : RayCast3D = $IFV_tower/IFV_main_turret/Aim_ray
@onready var reload_timer : Timer = $Reload_timer
@onready var ui : Control = $Player_UI
@onready var reticle : Control = $Player_UI/Reticle
@onready var reload_text : Control = $Player_UI/TimerCenter/Reload

@onready var mult_sync : MultiplayerSynchronizer = $MultiplayerSynchronizer


# Runtime Variables:
var accumulated_speed : float = 0.0
var is_reloaded : bool = false
var acc_rot_x : float = 0.0

func _ready() -> void:
	mult_sync.set_multiplayer_authority(str(name).to_int())	
	
	if mult_sync.get_multiplayer_authority() != multiplayer.get_unique_id():
		print("No match: ", name)
		return
	
	first_person_cam.make_current()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	reticle.modulate = Color.RED
	reload_timer.start()


func _process(delta: float) -> void:
	if mult_sync.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	if Input.is_action_pressed("player_shoot"):
		if is_reloaded:
			fire()
	reload_text.text = "%.1f" % reload_timer.time_left


func _physics_process(delta: float) -> void:
	if mult_sync.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("player_forward"):
		if (abs(accumulated_speed) < MAX_FORWARD_SPEED):
			accumulated_speed -= ACCELERATION * delta
	elif Input.is_action_pressed("player_backward"):
		if (abs(accumulated_speed) < MAX_REVERSE_SPEED):
			accumulated_speed += ACCELERATION * delta
	else:
		if (abs(accumulated_speed) > 0.01):
			accumulated_speed *= DEACCELERATION
		else:
			accumulated_speed = 0
		#print(accumulated_speed)
	#accumulated_speed = clamp(accumulated_speed, MAX_REVERSE_SPEED, MAX_FORWARD_SPEED)
	translate(Vector3(0, 0, accumulated_speed))
	move_and_slide()

func _input(event: InputEvent) -> void:
	if mult_sync.get_multiplayer_authority() != multiplayer.get_unique_id():
		return
		
	# Handle mouse cursor capturing and release
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event.is_action_pressed("player_toggle_camera"):
		if first_person_cam.is_current():
			third_person_cam.make_current()
		else:
			first_person_cam.make_current()
	if event.is_action_pressed("player_zoom"):
		if first_person_cam.fov == NORMAL_FOV:
			first_person_cam.fov = ZOOM_FOV
			third_person_cam.fov = ZOOM_FOV
		else:
			first_person_cam.fov = NORMAL_FOV
			third_person_cam.fov = NORMAL_FOV
	
	## WARNING This needs rework to properly clamp the transform rotation
	if event is InputEventMouseMotion:
		var rot_y = -event.relative.x / Global.mouseXSensibility
		var rot_x = -event.relative.y / Global.mouseYSensibility
		# Rotate tower
		tower.rotate_y(rot_y)
		acc_rot_x += rot_x
		acc_rot_x = clamp(acc_rot_x, deg_to_rad(MAIN_GUN_MAX_LOWER_ANGLE), deg_to_rad(MAIN_GUN_MAX_RAISE_ANGLE))
		# Raise or Lower main gun if between limits
		if (acc_rot_x > deg_to_rad(MAIN_GUN_MAX_LOWER_ANGLE) && acc_rot_x < deg_to_rad(MAIN_GUN_MAX_RAISE_ANGLE)):
			first_person_cam.rotate_x(rot_x)
			third_person_cam.rotate_x(rot_x)
			main_gun.rotate_x(rot_x)
			main_gun.transform = main_gun.transform.orthonormalized()
			first_person_cam.transform = first_person_cam.transform.orthonormalized()
			#tower.transform = main_gun.transform.orthonormalized()
		
func fire() -> void:
	is_reloaded = false
	print("Fire in the hole!")
	reload_timer.start()
	reticle.modulate = Color.RED
	

func _on_reload_timer_timeout() -> void:
	if mult_sync.get_multiplayer_authority() != multiplayer.get_unique_id():
		pass
	is_reloaded = true
	reticle.modulate = Color.WHITE
