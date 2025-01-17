extends StaticBody3D

## On-ready variables
# Cameras
@onready var fp_cam = $"MeshTurret/MeshBarrel/1stPersonCam"
@onready var tp_cam = $"MeshTurret/MeshBarrel/SpringArm3D/3rdPersonCam"
var current_camera
# Tank turret (player movement)
@onready var turret_barrel = $MeshTurret/MeshBarrel
@onready var pipe = $MeshTurret/MeshBarrel/MeshBarrelPipe
# Weapon related
#@onready var weapon_spawn = $MeshTurret/MeshBarrel/MeshBarrelPipe/RoundSpawn
@onready var fire_decal = $MeshTurret/MeshBarrel/MeshBarrelPipe/fire_decal
var rocket_instance
var update_rocket_target : bool = false

# Animation
@onready var anim = $AnimationPlayer

## Internal variables
# Can fire
var can_shoot : bool = true
var player_in_control : bool = true
signal player_fires

var selected_weapon
## PreLoads
@export_category("Player Weapons")
@export var weapon_1 : PackedScene = load("res://tanks/scenes/tank_round.tscn")
@export var weapon_2 : PackedScene = load("res://tanks/scenes/tow_ammo.tscn")

# Direct space state
var space

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	selected_weapon = weapon_1 # select the first weapon
	
	fp_cam.current = true
	tp_cam.current = false
	current_camera = fp_cam
	space = get_world_3d().direct_space_state

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
		
	if player_in_control and event is InputEventMouseMotion:
		# Turn tower
		rotation.y -= event.relative.x / Global.mouseXSensibility
		
		# Lift / Lower the pipe
		turret_barrel.rotation.x -= -event.relative.y / Global.mouseYSensibility
		turret_barrel.rotation.x = clamp(turret_barrel.rotation.x, deg_to_rad(-50),deg_to_rad(20))
		return
	
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

func player_make_current() -> void:
	player_in_control = true

func player_elsewhere() -> void:
	player_in_control = false

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fire":
		can_shoot = true

func _on_rocket_collision_detected() -> void:
	rocket_instance.despawn()
	rocket_instance = null
	can_shoot = true
	update_rocket_target = false
