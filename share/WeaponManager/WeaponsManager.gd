extends Node3D
class_name WeaponManager

@export var Animation_Player : AnimationPlayer

var Current_Weapon = null
var Weapon_Stack = [] # An Array of weapons in game
var Weapon_Indicator = 0 # Current starting weapon
var Next_Weapon = null
var Weapon_List = {}
var Ammo

var charge_time = 0
var millis = 0
var in_ammo_zone = false

@export var main_weapon_scene : PackedScene
@export var main_spawn_parent : NodePath
@export var secondary_weapon_scene : PackedScene
@export var secondary_spawn_parent : NodePath
var secondary_spawns_at_main : bool # Retrieve this info from Weapon Resource of the Weapon
@export var machinegun_scene : PackedScene
@export var machinegun_spawn_parent : NodePath

@export var Start_Weapons:Array[String]
@export var _weapon_paths : Array[NodePath] # Search path for weapon spawns
@export var _weapon_scenes:Array[PackedScene] # Weapons scenes that will be spawned


signal weapon_changed(weapon_side_texture:Texture2D)
signal weapon_update_ammo(weapon_ammo:Array)
signal weapon_update_stack(weapon_stack:Array)
signal equipped_weapon(weapon_weapon_resource:Weapon_Resource)

var HitScan_SpawnPoint
var manager_enabled : bool = true

# Nodes for the different ammo types
var controlled_node
var guided_node

# Help variables for different ammo types
var track_controlled : bool = false


enum {
	HITSCAN = 1,
	PROJECTILE = 2,
	GUIDED = 4,
	CONTROLLED = 8,
	CHARGED = 16
}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func Initialize():
	# Finding Weapons
	print("Finding Weapons")
	if main_weapon_scene != null and main_spawn_parent != null:
		print("addin main")
		_weapon_scenes.append(main_weapon_scene)
		var main_weapon = main_weapon_scene.instantiate()
		get_node(main_spawn_parent).add_child(main_weapon)
		Weapon_List[main_weapon.weapon_resource.Weapon_Name] = main_weapon
		
	if secondary_weapon_scene != null and secondary_spawn_parent != null:
		print("addin secondary")
		_weapon_scenes.append(secondary_weapon_scene)
		var secondary_weapon = secondary_weapon_scene.instantiate()
		get_node(secondary_spawn_parent).add_child(secondary_weapon)
		Weapon_List[secondary_weapon.weapon_resource.Weapon_Name] = secondary_weapon
		
	if machinegun_scene != null and machinegun_spawn_parent != null:
		print("addin mg")
		_weapon_scenes.append(machinegun_scene)
		var machinegun_weapon = machinegun_scene.instantiate()
		get_node(machinegun_spawn_parent).add_child(machinegun_weapon)
		Weapon_List[machinegun_weapon.weapon_resource.Weapon_Name] = machinegun_weapon
	
	for i in Start_Weapons:
		Weapon_Stack.push_back(i) # Add out start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[Weapon_Indicator]]
	
	#Current_Weapon.visible = true
	print("Current weapon name: " + var_to_str(Current_Weapon.weapon_resource.Weapon_Name))
	emit_signal("weapon_update_stack", Weapon_Stack)
	enter()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event):
	print("Unhandled input events starts")
	if not manager_enabled:
		print("WeaponManager not enabled")
		return
	if Current_Weapon == null:
		print("No weapon, return")
		return
	if track_controlled:
		print("Tracking...")
		Track_Controlled()
	if event.is_action_pressed("player_select_weapon_1"):
		CheckWeapon(Weapon_Indicator, 0)
	elif event.is_action_pressed("player_select_weapon_2"):
		CheckWeapon(Weapon_Indicator, 1)
	elif event.is_action_pressed("player_select_weapon_3"):
		CheckWeapon(Weapon_Indicator, 2)
	#elif event.is_action_pressed("player_select_weapon_4"):
		#CheckWeapon(Weapon_Indicator, 3)
	#elif event.is_action_pressed("player_select_weapon_5"):
		#CheckWeapon(Weapon_Indicator, 4)
	elif event.is_action_pressed("player_shoot"):
		match Current_Weapon.weapon_resource.Type:
			#NULL:
				#print("Weapon Type not chosen!")
			HITSCAN:
				#shoot(0.0)
				print("Hitscan weapon shoots <TODO>")
			PROJECTILE:
				print("Projectile weapon shoots")
				shoot()
			GUIDED:
				print("Guided weapon shoots")
				shoot()
			CONTROLLED:
				print("Player controlled weapon shoots")
				shoot()
			CHARGED:
				millis = Time.get_ticks_msec()
				print("Starting charging...")
	elif event.is_action_released("player_shoot"): # At button release 
		match Current_Weapon.weapon_resource.Type:
			#NULL:
				#pass
			HITSCAN:
				pass
			PROJECTILE:
				pass
			GUIDED:
				pass
			CONTROLLED:
				pass
			CHARGED:
				charge_time = (Time.get_ticks_msec() - millis) / 1000
				print("Charge time was ", charge_time, " seconds")
				print("Charged weapon shoots!")
	elif event.is_action_pressed("player_reload"):
		reload()
	print("Unhandled input events ends")

func CheckWeapon(index:int, next_index:int):
	print("Next weapon idx: ", next_index)
	if next_index >= Start_Weapons.size():
		print("Next idx is greater than Starting weapons.")
		print(var_to_str(Start_Weapons.size()))
		# Not this many weapons
		return
	if index != next_index:
		print("Setting new weapon ", Weapon_Stack[next_index])
		Weapon_Indicator = next_index
		exit(Weapon_Stack[Weapon_Indicator])

# Enter next weapon
# Missing error handling
func enter():
	if Animation_Player:
		Animation_Player.queue(Current_Weapon.weapon_resource.Activate_Anim)
	print("Weapon Type is " + var_to_str(Current_Weapon.weapon_resource.Type))
	print("Projectile: ", PROJECTILE)
	print("Controlled: ", CONTROLLED)
	match Current_Weapon.weapon_resource.Type:
		#NULL:
			#print("Weapon Type not chosen!")
		HITSCAN:
			print("Hitscan")
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.weapon_resource.Ammo_Spawn_Node)
			Ammo = Current_Weapon.weapon_resource.Ammo_Scene
			print("Spawn: ", HitScan_SpawnPoint)
			print("Ammo: ", Ammo)
		PROJECTILE:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.weapon_resource.Ammo_Spawn_Node)
			Ammo = Current_Weapon.weapon_resource.Ammo_Scene
			print("Projectile")
			print("Spawn: ", HitScan_SpawnPoint)
			print("Ammo: ", Ammo)
		GUIDED:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.weapon_resource.Ammo_Spawn_Node)
			Ammo = Current_Weapon.weapon_resource.Ammo_Scene
			print("Guided")
			print("Spawn: ", HitScan_SpawnPoint)
			print("Ammo: ", Ammo)
		CONTROLLED:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.weapon_resource.Ammo_Spawn_Node)
			Ammo = Current_Weapon.weapon_resource.Ammo_Scene
			print("Controlled")
			print("Spawn: ", HitScan_SpawnPoint)
			print("Ammo: ", Ammo)
		CHARGED:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.weapon_resource.Ammo_Spawn_Node)
			Ammo = Current_Weapon.weapon_resource.Ammo_Scene
			print("Charged")
			print("Spawn: ", HitScan_SpawnPoint)
			print("Ammo: ", Ammo)
	emit_signal("equipped_weapon", Current_Weapon.weapon_resource)
	emit_signal("weapon_changed", Current_Weapon.weapon_resource.WeaponSideTexture)
	emit_signal("weapon_update_ammo", [Current_Weapon.weapon_resource.Current_Ammo, Current_Weapon.weapon_resource.Reserve_Ammo])

# Exit current weapon
func exit(_next_weapon:String):
	if _next_weapon != Current_Weapon.weapon_resource.Weapon_Name:
		if Animation_Player:
			if Animation_Player.get_current_animation() != Current_Weapon.weapon_resource.DeActivate_Anim:
				Animation_Player.play(Current_Weapon.weapon_resource.DeActivate_Anim)
				Next_Weapon = Weapon_List[_next_weapon]
		else:
			Next_Weapon = Weapon_List[_next_weapon]
			Change_Weapon(Next_Weapon)
	else:
		print("Same weapon, do nothing.")

func Change_Weapon(next_weapon):
	print(next_weapon.weapon_resource.Weapon_Name)
	Current_Weapon = next_weapon
	Next_Weapon = null
	enter()

func shoot(hold_time : float = 0.0):
	if Current_Weapon.weapon_resource.Current_Ammo > 0:
		if Animation_Player:
			if Animation_Player.is_playing():
				return
		var Camera_Collision = Get_Camera_Collision(true)
		match Current_Weapon.weapon_resource.Type:
			#NULL:
				#print("Weapon Type not chosen!")
			HITSCAN:
				SpawnAmmo(Camera_Collision)
			PROJECTILE:
				SpawnAmmo(Camera_Collision)
			GUIDED:
				if is_instance_valid(guided_node):
					print("INstance not valid at guided")
					return
				print("INstance valid at guided")
				SpawnAmmo(Camera_Collision)
			CONTROLLED:
				if is_instance_valid(controlled_node):
					print("INstance not valid at controlled")
					return
					print("INstance valid at controlled")
				SpawnAmmo(Camera_Collision)
			CHARGED:
				SpawnChargedBullet(Camera_Collision, hold_time)
		if Animation_Player:
			Animation_Player.play(Current_Weapon.weapon_resource.Shoot_Anim)
		if Current_Weapon.has_method("shoot_anim"):
			Current_Weapon.shoot_anim()
		Current_Weapon.weapon_resource.Current_Ammo -= 1
		emit_signal("weapon_update_ammo", [Current_Weapon.weapon_resource.Current_Ammo, Current_Weapon.weapon_resource.Reserve_Ammo])
		
	else:
		if Current_Weapon.has_method("stop_shoot_anim"):
			Current_Weapon.stop_shoot_anim()
		reload()

func reload():
	if 0 < Current_Weapon.weapon_resource.Reserve_Ammo and Current_Weapon.weapon_resource.Current_Ammo < Current_Weapon.weapon_resource.Full_Magazine:
		if Animation_Player:
			if Animation_Player.is_playing():
				return
			else:
				Animation_Player.play(Current_Weapon.weapon_resource.Reload_Anim)
		if (Current_Weapon.weapon_resource.Reserve_Ammo + Current_Weapon.weapon_resource.Current_Ammo) <= Current_Weapon.weapon_resource.Full_Magazine:
			Current_Weapon.weapon_resource.Current_Ammo = Current_Weapon.weapon_resource.Reserve_Ammo + Current_Weapon.weapon_resource.Current_Ammo
			Current_Weapon.weapon_resource.Reserve_Ammo = 0
		else:
			Current_Weapon.weapon_resource.Reserve_Ammo = Current_Weapon.weapon_resource.Reserve_Ammo - (Current_Weapon.weapon_resource.Full_Magazine - Current_Weapon.weapon_resource.Current_Ammo)
			Current_Weapon.weapon_resource.Current_Ammo = Current_Weapon.weapon_resource.Full_Magazine
		emit_signal("weapon_update_ammo", [Current_Weapon.weapon_resource.Current_Ammo, Current_Weapon.weapon_resource.Reserve_Ammo])

 
func Get_Camera_Collision(_use_ray_end : bool = false)->Vector3:
	# Get current camera view
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	# And shoot a ray from it.
	var RayOrigin = camera.project_ray_origin(viewport/2)
	var RayEnd = RayOrigin + camera.project_ray_normal(viewport/2) * Current_Weapon.weapon_resource.Weapon_Range
	
	# If _use_ray_end is given, exit here.
	if _use_ray_end:
		return RayEnd
	
	var RayParameters = PhysicsRayQueryParameters3D.create(RayOrigin,RayEnd)
	
	# TODO exclude team mates from the raycast
	var exclude_bodies : Array  # List of player's bodies
	for body in Global.player_body:
		exclude_bodies.append(body.get_rid())
	if controlled_node and not controlled_node.is_queued_for_deletion() and is_instance_valid(controlled_node): 
		exclude_bodies.append(controlled_node.get_rid())
	if guided_node and not guided_node.is_queued_for_deletion() and is_instance_valid(guided_node):
		exclude_bodies.append(guided_node.get_rid())
	RayParameters.set_exclude(exclude_bodies)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(RayParameters)
	if not Intersection.is_empty():
		#print("points at: " + var_to_str(Intersection.position))
		return Intersection.position
	else:
		#print("points at end of ray: " + var_to_str(RayEnd))
		return RayEnd

func HitScan_Collision(collision_point):
	# Get direction between collision point and bullet spawnpoint as normalized vector
	var HitScan_Direction = (collision_point - HitScan_SpawnPoint.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(HitScan_SpawnPoint.get_global_transform().origin, collision_point + HitScan_Direction * 2)
	
	var HitScan_Collision_Point = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if HitScan_Collision_Point:
		SpawnAmmo(collision_point)

func HitScan_Damage(Collider):
	if Collider.is_in_group("Enemy") and Collider.has_method("hit"):
		Collider.hit(Current_Weapon.weapon_resource.Weapon_Damage)
	
func SpawnAmmo(direction):
	var root_node = get_tree().get_root()
	var ammo_node = Ammo.instantiate()
	ammo_node.set_global_transform(HitScan_SpawnPoint.get_global_transform()) #.looking_at(direction))
	root_node.add_child(ammo_node)
	
	# Collision exceptions with team players. (Now just one)
	for body in Global.player_body:
		if ammo_node.has_method("add_collision_exception_with") and is_instance_valid(body):
			ammo_node.add_collision_exception_with(body)
	
	#print("Bullet's global transform: " + var_to_str(bullet_node.global_transform))
	#print("Bullet's global transform origin: " + var_to_str(bullet_node.global_transform.origin))
	#print("Bullet's should look at: " + var_to_str(direction))
	if ammo_node.has_method("apply_motion"):
		ammo_node.apply_motion(Current_Weapon.weapon_resource.Weapon_Damage, Current_Weapon.weapon_resource.Weapon_Ammo_Speed, direction)
	match Current_Weapon.weapon_resource.Type:
		#NULL:
			#print("Weapon Type not chosen!")
		HITSCAN:
			pass
		PROJECTILE:
			pass
		GUIDED:
			guided_node = ammo_node
			guided_node.player_make_current()
			guided_node.connect("guided_despawns", _on_guided_despawns)
			if get_parent().has_method("player_elsewhere"):
				get_parent().player_elsewhere()
		CONTROLLED:
			controlled_node = ammo_node
			controlled_node.set_player(get_parent())
			controlled_node.connect("controlled_despawns", _on_controlled_despawns)
			track_controlled = true
		CHARGED:
			pass

func SpawnChargedBullet(direction, hold_time):
	var root_node = get_tree().get_root()
	var bullet_node = Ammo.instantiate()
	bullet_node.set_global_transform(HitScan_SpawnPoint.global_transform.looking_at(direction))
	root_node.add_child(bullet_node)
	bullet_node.initialize(hold_time)

func Track_Controlled():
	if controlled_node == null:
		print("Tracking node null")
		return
	print("Getting cam collision")
	var ray_position = Get_Camera_Collision() #false, controlled_node
	print("Setting transform for update")
	var target_transform = Transform3D(Basis.IDENTITY, ray_position)
	print("Updating transform to the controlled")
	controlled_node.update_target(target_transform)
	print("Tracking ends")

func RefillAmmo():
	for weapon in Weapon_Stack:
		if (Weapon_List[weapon].Reserve_Ammo + Weapon_List[weapon].Current_Ammo + Weapon_List[weapon].Full_Magazine) <= Weapon_List[weapon].Max_Ammo:
				Weapon_List[weapon].Reserve_Ammo += Weapon_List[weapon].Full_Magazine
		else:
			Weapon_List[weapon].Reserve_Ammo = Weapon_List[weapon].Max_Ammo - Weapon_List[weapon].Full_Magazine
	emit_signal("weapon_update_ammo", [Current_Weapon.weapon_resource.Current_Ammo, Current_Weapon.weapon_resource.Reserve_Ammo])

func _on_animation_player_animation_finished(anim_name):
	# If current weapon has been deactivated, equip next one.
	if anim_name == Current_Weapon.weapon_resource.DeActivate_Anim:
		Change_Weapon(Next_Weapon)
		return
	
	# Autofire weapons continue if pressed.
	if anim_name == Current_Weapon.weapon_resource.Shoot_Anim:
		if Current_Weapon.weapon_resource.has_auto_fire and Input.is_action_pressed("player_shoot"):
			shoot(0.0)
			return
		# Single and Burst fire weapons stop here.
		if Current_Weapon.has_method("stop_shoot_anim"):
			Current_Weapon.stop_shoot_anim()

func _on_ammo_detection_body_entered(body):
	if body.is_in_group("AmmoReserve"):
		in_ammo_zone = true
		$AmmoTimer.start()
	


func _on_ammo_detection_body_exited(body):
	if body.is_in_group("AmmoReserve"):
		if not $AmmoTimer.is_stopped():
			$AmmoTimer.stop()
		in_ammo_zone = false


func _on_ammo_timer_timeout():
	if in_ammo_zone:
		RefillAmmo()
		$AmmoTimer.start()
	

func _on_controlled_despawns():
	print("Despawn signal emited from controlled.")
	track_controlled = false
	controlled_node = null

func _on_guided_despawns():
	guided_node = null
