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
@onready var weapon_spawn = $MeshTurret/MeshBarrel/MeshBarrelPipe/RoundSpawn
@onready var fire_decal = $MeshTurret/MeshBarrel/MeshBarrelPipe/fire_decal
var rocket_instance
var update_rocket_target : bool = false

# Animation
@onready var anim = $AnimationPlayer

## Internal variables
# Can fire
var can_shoot : bool = true
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
		get_camera_ray_collision()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
		
	if event is InputEventMouseMotion:
		# Turn tower
		rotation.y -= event.relative.x / Global.mouseXSensibility
		
		# Lift / Lower the pipe
		turret_barrel.rotation.x -= -event.relative.y / Global.mouseYSensibility
		turret_barrel.rotation.x = clamp(turret_barrel.rotation.x, deg_to_rad(-50),deg_to_rad(15))
		return
	
	if event.is_action_released("player_toggle_camera"):
		if fp_cam.current:
			fp_cam.current = false
			tp_cam.current = true
			current_camera = tp_cam
			
		else:
			tp_cam.current = false
			fp_cam.current = true
			current_camera = fp_cam
		return
	if event.is_action_pressed("player_next_weapon"):
		if selected_weapon == weapon_1:
			selected_weapon = weapon_2
		else:
			selected_weapon = weapon_1 
		return
	if event.is_action_pressed("player_shoot"):
		if can_shoot:
			if selected_weapon == weapon_1:
				emit_signal("player_fires")
				# Add a wait time (animation time)
				# Tween implementation
				anim.play("fire")
				#var fire_tween = get_tree().create_tween()
				#fire_tween.tween_property(pipe, "position", Vector3(pipe.position.x, pipe.position.y, pipe.position.z+0.25), 0.1)
				#fire_tween.tween_property(pipe, "position", pipe.position, 0.1)
				# Instantiate the shot tank round or weapon
				var root_scene = get_tree().get_root()
				var weapon_instance = selected_weapon.instantiate()
				weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
				root_scene.add_child(weapon_instance)
				
				var barrel_tween = get_tree().create_tween()
				var mid_anim_point = Vector3(turret_barrel.rotation.x - deg_to_rad(5), turret_barrel.rotation.y, turret_barrel.rotation.z)
				barrel_tween.tween_property(turret_barrel, "rotation", mid_anim_point, 0.1)
				barrel_tween.tween_property(turret_barrel, "rotation", turret_barrel.rotation, 0.1)
				can_shoot = false
			elif selected_weapon == weapon_2:
				# Instantiate the shot tank round or weapon
				var root_scene = get_tree().get_root()
				var weapon_instance = selected_weapon.instantiate()
				weapon_instance.set_global_transform(weapon_spawn.get_global_transform())
				root_scene.add_child(weapon_instance)
				rocket_instance = weapon_instance
				rocket_instance.set_player(get_rid())
				
				rocket_instance.connect("collision_detected_signal", _on_rocket_collision_detected)
				update_rocket_target = true
				can_shoot = false
		return
	

func get_camera_ray_collision():
	var query = PhysicsRayQueryParameters3D.create(current_camera.global_position,
	current_camera.global_position - current_camera.global_transform.basis.z * 1000)
	var collision = space.intersect_ray(query)
	if collision:
		var target_transform = Transform3D(Basis.IDENTITY, collision.position)
		rocket_instance.update_target(target_transform)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fire":
		can_shoot = true

func _on_rocket_collision_detected() -> void:
	rocket_instance.disconnect("collision_detected_signal", _on_rocket_collision_detected)
	rocket_instance.queue_free()
	rocket_instance = null
	can_shoot = true
	update_rocket_target = false
