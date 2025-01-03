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

@export var _weapon_scenes:Array[PackedScene]
@export var Start_Weapons:Array[String]

signal weapon_changed(weapon_side_texture:Texture2D)
signal weapon_update_ammo(weapon_ammo:Array)
signal weapon_update_stack(weapon_stack:Array)
signal equipped_weapon(weapon_attributes:Weapon_Resource)

var HitScan_SpawnPoint : Marker3D
var manager_enabled : bool = true

enum {
	NULL,
	HITSCAN,
	PROJECTILE,
	GUIDED,
	CONTROLLED,
	CHARGED
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event):
	if not manager_enabled:
		return
	if Current_Weapon == null:
		print("No weapon, return")
		return
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
		if Current_Weapon == null:
			print("No weapon, return")
			return
		match Current_Weapon.attributes.Type:
			NULL:
				print("Weapon Type not chosen!")
			HITSCAN:
				#shoot(0.0)
				print("Hitscan weapon shoots <TODO>")
			PROJECTILE:
				print("Projectile weapon shoots")
				#shoot(0.0)
			GUIDED:
				print("Guided weapon shoots <TODO>")
			CONTROLLED:
				print("Player controlled weapon shoots <TODO>")
			CHARGED:
				millis = Time.get_ticks_msec()
				print("Starting charging...")
	elif event.is_action_released("player_shoot"): # At button release 
		if Current_Weapon == null:
			print("No weapon, return")
			return
		match Current_Weapon.attributes.Type:
			NULL:
				pass
			HITSCAN:
				#shoot(0.0)
				#print("Hitscan weapon shoots <TODO>")
				pass
			PROJECTILE:
				pass
				#print("Projectile weapon shoots")
				#shoot(0.0)
			GUIDED:
				pass
				#print("Guided weapon shoots <TODO>")
			CONTROLLED:
				pass
				#print("Player controlled weapon shoots <TODO>")
			CHARGED:
				charge_time = (Time.get_ticks_msec() - millis) / 1000
				print("Charge time was ", charge_time, " seconds")
				print("Charged weapon shoots!")
	elif event.is_action_pressed("player_reload"):
		if Current_Weapon == null:
			print("No weapon, return")
			return
		reload()

func CheckWeapon(index:int, next_index:int):
	print(next_index)
	if next_index >= Start_Weapons.size():
		print(var_to_str(Start_Weapons.size()))
		# Not this many weapons
		return
	if index != next_index:
		Weapon_Indicator = next_index
		exit(Weapon_Stack[Weapon_Indicator])

func Initialize():
	# Creating a Weapon Node Dictionary
	for weapon in _weapon_scenes:
		var spawn_weapon = weapon.instantiate()
		add_child(spawn_weapon)
		spawn_weapon.visible = false
		# Save node to the Weapon list.
		Weapon_List[spawn_weapon.attributes.Weapon_Name] = spawn_weapon
		
	
	for i in Start_Weapons:
		Weapon_Stack.push_back(i) # Add out start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[Weapon_Indicator]]
	Current_Weapon.visible = true
	print("Current weapon name: " + var_to_str(Current_Weapon.attributes.Weapon_Name))
	emit_signal("weapon_update_stack", Weapon_Stack)
	enter()

# Enter next weapon
# Missing error handling
func enter():
	Animation_Player.queue(Current_Weapon.attributes.Activate_Anim)
	print("Weapon Type is " + var_to_str(Current_Weapon.attributes.Type))
	match Current_Weapon.attributes.Type:
		NULL:
			print("Weapon Type not chosen!")
		HITSCAN:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.attributes.Ammo_Spawn_Node)
			Ammo = Current_Weapon.attributes.Ammo_Scene
		PROJECTILE:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.attributes.Ammo_Spawn_Node)
			print(HitScan_SpawnPoint)
			Ammo = Current_Weapon.attributes.Ammo_Scene
		GUIDED:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.attributes.Ammo_Spawn_Node)
			Ammo = Current_Weapon.attributes.Ammo_Scene
		CONTROLLED:
			HitScan_SpawnPoint = Current_Weapon.find_child(Current_Weapon.attributes.Ammo_Spawn_Node)
			Ammo = Current_Weapon.attributes.Ammo_Scene
	emit_signal("equipped_weapon", Current_Weapon.attributes)
	emit_signal("weapon_changed", Current_Weapon.attributes.WeaponSideTexture)
	emit_signal("weapon_update_ammo", [Current_Weapon.attributes.Current_Ammo, Current_Weapon.attributes.Reserve_Ammo])

# Exit current weapon
func exit(_next_weapon:String):
	if _next_weapon != Current_Weapon.attributes.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.attributes.DeActivate_Anim:
			Animation_Player.play(Current_Weapon.attributes.DeActivate_Anim)
			Next_Weapon = Weapon_List[_next_weapon]

func Change_Weapon(next_weapon):
	print(next_weapon.attributes.Weapon_Name)
	Current_Weapon = next_weapon
	Next_Weapon = null
	enter()

func shoot(hold_time):
	if Current_Weapon.attributes.Current_Ammo > 0 and not Animation_Player.is_playing():
		var Camera_Collision = Get_Camera_Collision(true)
		match Current_Weapon.attributes.Type:
			NULL:
				print("Weapon Type not chosen!")
			HITSCAN:
				SpawnBullet(Camera_Collision)
			PROJECTILE:
				SpawnBullet(Camera_Collision)
			CHARGED:
				SpawnChargedBullet(Camera_Collision, hold_time)
		Animation_Player.play(Current_Weapon.attributes.Shoot_Anim)
		if Current_Weapon.has_method("shoot_anim"):
			Current_Weapon.shoot_anim()
		Current_Weapon.attributes.Current_Ammo -= 1
		emit_signal("weapon_update_ammo", [Current_Weapon.attributes.Current_Ammo, Current_Weapon.attributes.Reserve_Ammo])
		
	else:
		if Current_Weapon.has_method("stop_shoot_anim"):
			Current_Weapon.stop_shoot_anim()
		reload()

func reload():
	if 0 < Current_Weapon.attributes.Reserve_Ammo and Current_Weapon.attributes.Current_Ammo < Current_Weapon.attributes.Full_Magazine:
		if not Animation_Player.is_playing():
			Animation_Player.play(Current_Weapon.attributes.Reload_Anim)
			if (Current_Weapon.attributes.Reserve_Ammo + Current_Weapon.attributes.Current_Ammo) <= Current_Weapon.attributes.Full_Magazine:
				Current_Weapon.attributes.Current_Ammo = Current_Weapon.attributes.Reserve_Ammo + Current_Weapon.attributes.Current_Ammo
				Current_Weapon.attributes.Reserve_Ammo = 0
			else:
				Current_Weapon.attributes.Reserve_Ammo = Current_Weapon.attributes.Reserve_Ammo - (Current_Weapon.attributes.Full_Magazine - Current_Weapon.attributes.Current_Ammo)
				Current_Weapon.attributes.Current_Ammo = Current_Weapon.attributes.Full_Magazine
			emit_signal("weapon_update_ammo", [Current_Weapon.attributes.Current_Ammo, Current_Weapon.attributes.Reserve_Ammo])
	

#@param: _use_ray_end : bool
func Get_Camera_Collision(_use_ray_end : bool = false)->Vector3:
	# Get current camera view
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	# And shoot a ray from it.
	var RayOrigin = camera.project_ray_origin(viewport/2)
	var RayEnd = RayOrigin + camera.project_ray_normal(viewport/2) * Current_Weapon.attributes.Weapon_Range
	
	# If _use_ray_end is given, exit here.
	if _use_ray_end:
		return RayEnd
	
	var RayParameters = PhysicsRayQueryParameters3D.create(RayOrigin,RayEnd)
	
	# TODO exclude team mates from the raycast
	var exclude_bodies : Array = [Global.player]
	RayParameters.set_exclude(exclude_bodies)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(RayParameters)
	if not Intersection.is_empty():
		print("points at: " + var_to_str(Intersection.position))
		return Intersection.position
	else:
		print("points at end of ray: " + var_to_str(RayEnd))
		return RayEnd
		
func HitScan_Collision(collision_point):
	# Get direction between collision point and bullet spawnpoint as normalized vector
	var HitScan_Direction = (collision_point - HitScan_SpawnPoint.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(HitScan_SpawnPoint.get_global_transform().origin, collision_point + HitScan_Direction * 2)
	
	var HitScan_Collision_Point = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if HitScan_Collision_Point:
		SpawnBullet(collision_point)

func HitScan_Damage(Collider):
	if Collider.is_in_group("Enemy") and Collider.has_method("hit"):
		Collider.hit(Current_Weapon.attributes.Weapon_Damage)
	
func SpawnBullet(direction):
	var root_node = get_tree().get_root()
	var bullet_node = Ammo.instantiate()
	bullet_node.set_global_transform(HitScan_SpawnPoint.global_transform.looking_at(direction))
	root_node.add_child(bullet_node)
	
	# Collision exceptions with team players. (Now just one)
	bullet_node.add_collision_exception_with(Global.player)
	
	#print("Bullet's global transform: " + var_to_str(bullet_node.global_transform))
	#print("Bullet's global transform origin: " + var_to_str(bullet_node.global_transform.origin))
	#print("Bullet's should look at: " + var_to_str(direction))
	if bullet_node.has_method("apply_motion"):
		bullet_node.apply_motion(Current_Weapon.attributes.Weapon_Damage, Current_Weapon.attributes.Weapon_Ammo_Speed, direction)

func SpawnChargedBullet(direction, hold_time):
	var root_node = get_tree().get_root()
	var bullet_node = Ammo.instantiate()
	bullet_node.set_global_transform(HitScan_SpawnPoint.global_transform.looking_at(direction))
	root_node.add_child(bullet_node)
	bullet_node.initialize(hold_time)

func RefillAmmo():
	for weapon in Weapon_Stack:
		if (Weapon_List[weapon].Reserve_Ammo + Weapon_List[weapon].Current_Ammo + Weapon_List[weapon].Full_Magazine) <= Weapon_List[weapon].Max_Ammo:
				Weapon_List[weapon].Reserve_Ammo += Weapon_List[weapon].Full_Magazine
		else:
			Weapon_List[weapon].Reserve_Ammo = Weapon_List[weapon].Max_Ammo - Weapon_List[weapon].Full_Magazine
	emit_signal("weapon_update_ammo", [Current_Weapon.attributes.Current_Ammo, Current_Weapon.attributes.Reserve_Ammo])

func _on_animation_player_animation_finished(anim_name):
	# If current weapon has been deactivated, equip next one.
	if anim_name == Current_Weapon.attributes.DeActivate_Anim:
		Change_Weapon(Next_Weapon)
		return
	
	# Autofire weapons continue if pressed.
	if anim_name == Current_Weapon.attributes.Shoot_Anim:
		if Current_Weapon.attributes.has_auto_fire and Input.is_action_pressed("player_shoot"):
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
	
