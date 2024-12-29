extends StaticBody3D

## On-ready variables
# Cameras
@onready var fp_cam = $"MeshTurret/MeshBarrel/1stPersonCam"
@onready var tp_cam = $"MeshTurret/MeshBarrel/SpringArm3D/3rdPersonCam"

# Tank turret (player movement)
@onready var turret_barrel = $MeshTurret/MeshBarrel

# Weapon related
@onready var weapon_spawn = $MeshTurret/MeshBarrel/MeshBarrelPipe/RoundSpawn
@onready var fire_decal = $MeshTurret/MeshBarrel/MeshBarrelPipe/fire_decal

# Animation
@onready var anim = $AnimationPlayer

## Internal variables
# Can fire
var can_shoot : bool = true
signal player_fires

## PreLoads
@export_category("Player Weapons")
@export var weapon_1 : PackedScene = preload("res://tanks/scenes/tank_round.tscn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	fp_cam.current = true
	tp_cam.current = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseMotion:
		# Turn tower
		rotation.y -= event.relative.x / Global.mouseXSensibility
		
		# Lift / Lower the pipe
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
		if can_shoot:
			emit_signal("player_fires")
			# Add a wait time (animation time)
			can_shoot = false
			anim.play("fire")
			
			# Instantiate the shot tank round or weapon
			var root_scene = get_tree().get_root()
			var weapon_instance = weapon_1.instantiate()
			weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
			root_scene.add_child(weapon_instance)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fire":
		can_shoot = true
