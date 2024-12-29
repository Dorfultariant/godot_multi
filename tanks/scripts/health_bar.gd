extends Node3D

class_name HealthComponent

@export var health_value : float = 100.0 # Current health value
@export var health_min : float = 0.0 # Min health
@export var health_max : float = 100.0 # Max health
@export var reviveable : bool = true # If can be revived
@export var replenishes_health : bool = false # Can replenish health over time
@export var replenish_health_per_second : float = 0.0 # HP per second
@export var replenish_health_wait_time : float = 0.0 # Wait this long until replenish begins
@export var show_hitnumbers : bool = false

# Variables
var already_killed : bool = false
var killed_by_hit : bool = false
var replenish_timer : float = 0.0

# Constants
const ADD_HEALTH_SUCCESFUL	: bool = 1
const ADD_HEALTH_FAILED		: bool = 0
# Damage types
const DAMAGE_TYPE_NULL			: int = 0
const DAMAGE_TYPE_GENERAL		: int = 1
const DAMAGE_TYPE_WATER			: int = 2
const DAMAGE_TYPE_WATER_SPIll	: int = 3
const DAMAGE_TYPE_LAVA			: int = 4
const DAMAGE_TYPE_LAVA_SPILL	: int = 5
const DAMAGE_TYPE_AREA			: int = 6


# Test for attaching a signal to a parent.
signal health_update(health_amount : float)
signal health_reached_min()
signal revive_succesful(health_amount:float)

var health_text

var hitnumber = preload("res://scenes/shared/hit_number.tscn")

# General hit function for every damage type. Testing 
# Inputs:
# DamageType : int
# DamageValue : float
# DamagePosition : Vector3
func hit(_damage_type : int = 0, _damage_value : float = 0.0, _hit_position : Vector3 = Vector3()) -> Array:
	killed_by_hit = false # If this is changed, hit killed it, otherwise it is false
	if already_killed:
		# Return killed statement = false, 0 damage done
		return [killed_by_hit, already_killed, 0.0]
	
	# Set the health replenish timer to zero as we took a hit
	replenish_timer = 0.0
	
	# Check the damage type
	match _damage_type:
		DAMAGE_TYPE_NULL:
			# No damage
			print("No damage")
			return [killed_by_hit, already_killed, 0.0]
		DAMAGE_TYPE_GENERAL:
			print("General damage")
			health_value -= _damage_value
		DAMAGE_TYPE_WATER:
			print("Water damage")
			health_value -= _damage_value
		DAMAGE_TYPE_WATER_SPIll:
			print("Water spill damage")
			health_value -= _damage_value
		DAMAGE_TYPE_LAVA:
			print("Lava damage")
			pass
		DAMAGE_TYPE_LAVA_SPILL:
			print("Lava spill damage")
			pass
		DAMAGE_TYPE_AREA:
			print("Area damage")
			_damage_value = _damage_value / max(1.0*(_hit_position - global_position).length(), 1.0)
			#print("Distance to explosion: " + var_to_str((_hit_position - global_position).length()))
			#print("Explosion damp: " + var_to_str(area_damage_damp))
			health_value -= _damage_value
	if show_hitnumbers:
		show_hitnumber(var_to_str(_damage_value), "-")
	
	
	if health_value <= health_min:
		health_value = health_min
		killed_by_hit = true
		already_killed = true
		emit_signal("health_reached_min")
	
	if health_text:
		health_text.text = var_to_str(health_value) + " hp"
	emit_signal("health_update", health_value)
	return [killed_by_hit, false, _damage_value]

# This function has two purposes, add health and revive the player.
# Returns success
func add_health(amount:float, _revived:bool = false) -> bool:
	if already_killed:
		if _revived:
			already_killed = false
			emit_signal("revive_succesful", amount)
		else:
			return ADD_HEALTH_FAILED
	health_value += amount

	if health_value > health_max:
		health_value = health_max
	
	if health_text:
		health_text.text = var_to_str(round(health_value)) + " hp"

	return ADD_HEALTH_SUCCESFUL

func show_hitnumber(damage_text : String, _sign : String = ""):
	# Instantiate the damage number and add to the world.
	var number = hitnumber.instantiate()
	number.set_text(_sign + damage_text)
	Global.spawn_node_on_world.add_child(number)
	number.global_position = global_position
	# Creating a tween to move 2.0 units upwards and then freeing itself
	var tween = get_tree().create_tween()
	tween.tween_property(number, "global_position", global_position + Vector3(0.0, 2.0, 0.0), 2.0)
	tween.tween_callback(number.queue_free)


func _ready():
	health_text = get_parent().find_child("HealthText")
	if health_text:
		health_text.text = var_to_str(round(health_max)) + " hp"

func _process(delta):
	# If we are killed, no reason to go further
	if already_killed:
		pass
	
	replenish_timer += delta
	if replenish_timer >= replenish_health_wait_time:
		add_health(delta * replenish_health_per_second)
	

