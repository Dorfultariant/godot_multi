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
	if update_rocket_target:
		update_rocket()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
		
	if player_in_control and event is InputEventMouseMotion:
		# Turn tower
		rotation.y -= event.relative.x / Global.mouseXSensibility
		
		# Lift / Lower the pipe
		turret_barrel.rotation.x -= -event.relative.y / Global.mouseYSensibility
		turret_barrel.rotation.x = clamp(turret_barrel.rotation.x, deg_to_rad(-50),deg_to_rad(15))
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
	#if event.is_action_pressed("player_next_weapon"):
		#if selected_weapon == weapon_1:
			#selected_weapon = weapon_2
		#else:
			#selected_weapon = weapon_1 
		#return
	#if event.is_action_pressed("player_shoot"):
		#if can_shoot:
			#if selected_weapon == weapon_1:
				#emit_signal("player_fires")
				## Add a wait time (animation time)
				## Tween implementation
				#anim.play("fire")
				##var fire_tween = get_tree().create_tween()
				##fire_tween.tween_property(pipe, "position", Vector3(pipe.position.x, pipe.position.y, pipe.position.z+0.25), 0.1)
				##fire_tween.tween_property(pipe, "position", pipe.position, 0.1)
				## Instantiate the shot tank round or weapon
				#var root_scene = get_tree().get_root()
				#var weapon_instance = selected_weapon.instantiate()
				#weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
				#root_scene.add_child(weapon_instance)
				#
				#var barrel_tween = get_tree().create_tween()
				#var mid_anim_point = Vector3(turret_barrel.rotation.x - deg_to_rad(5), turret_barrel.rotation.y, turret_barrel.rotation.z)
				#barrel_tween.tween_property(turret_barrel, "rotation", mid_anim_point, 0.1)
				#barrel_tween.tween_property(turret_barrel, "rotation", turret_barrel.rotation, 0.1)
				#can_shoot = false
			#elif selected_weapon == weapon_2:
				## Instantiate the shot tank round or weapon
				#var root_scene = get_tree().get_root()
				#var weapon_instance = selected_weapon.instantiate()
				#weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
				#root_scene.add_child(weapon_instance)
				#rocket_instance = weapon_instance
				#rocket_instance.set_player(get_rid())
				#
				#rocket_instance.connect("collision_detected_signal", _on_rocket_collision_detected)
				#update_rocket_target = true
				#can_shoot = false
		#return
	
func Get_Camera_Collision(_use_ray_end : bool = false)->Vector3:
	# Get current camera view
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	# And shoot a ray from it.
	var RayOrigin = camera.project_ray_origin(viewport/2)
	var RayEnd = RayOrigin + camera.project_ray_normal(viewport/2) * 2000
	
	# If _use_ray_end is given, exit here.
	if _use_ray_end:
		return RayEnd
	
	var RayParameters = PhysicsRayQueryParameters3D.create(RayOrigin,RayEnd)
	
	# TODO exclude team mates from the raycast
	var exclude_bodies : Array = [self, rocket_instance]
	RayParameters.set_exclude(exclude_bodies)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(RayParameters)
	if not Intersection.is_empty():
		print("points at: " + var_to_str(Intersection.position))
		return Intersection.position
	else:
		print("points at end of ray: " + var_to_str(RayEnd))
		return RayEnd
func update_rocket():
	var ray_position = Get_Camera_Collision()
	var target_transform = Transform3D(Basis.IDENTITY, ray_position)
	rocket_instance.update_target(target_transform)

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
