extends Resource

class_name Weapon_Resource

# Weapon info
@export var Weapon_Name : String
# Pictures
@export var WeaponSideTexture : Texture2D

# Animations
@export_category("Animations")
@export var Animation_Player_Path : String = "AnimationPlayer"
@export var Activate_Anim : String = "activate"
@export var Shoot_Anim : String = "fire"
@export var Reload_Anim : String = "reload"
@export var DeActivate_Anim : String = "deactivate"
@export var Speed_Scale : float = 1

# Animations
@export_category("Sounds")
@export var Activate_Sound : AudioStreamMP3
@export var Shoot_Sound : AudioStreamMP3
@export var Reload_Sound : AudioStreamMP3
@export var DeActivate_Sound : AudioStreamMP3
@export var Sound_Scale : float = 1

# Ammo variables
@export_category("Ammo")
@export var Ammo_Scene : PackedScene
@export var Ammo_Spawn_Node : String = "AmmoSpawn"
@export var Ammo_Spawns_At_Main : bool
@export_flags ("HitScan" , "Projectile" , "Guided", "Controlled", "Charged") var Type
@export var Current_Ammo : int # How many in the magazine
@export var Reserve_Ammo : int # Total ammo reserve in other magazines
@export var Full_Magazine : int # How many magazines
@export var Max_Ammo : int # Max amount of ammo

# Weapon variables
@export_category("Variables")
@export_range(0.0, 5000.0) var Weapon_Ammo_Speed : float
@export var Weapon_sway_angle_max : float # Value between 0 and 1, 0 is steady and 1 is max angle
@export var Weapon_sway_scale : float # Value between 0 and 1, 0 is steady and 1 is max angle
@export var Weapon_Aim_Position : Vector3
@export var Weapon_Aim_FOV : float
@export var Weapon_Range : int
@export var Weapon_Damage : int
@export var Weapon_Parent_Updates : bool

# Firemode
@export_category("Firemode")
@export_enum("single_fire", "burst_fire", "auto_fire") var firemode
