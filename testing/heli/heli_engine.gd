class_name HeliEngine extends Node3D

# Public variables
@export var max_hp : float = 140.0
@export var max_rpm : float = 2700.0
@export var power_delay : float = 2.0
@export var power_curve : Curve

# Private variables
var current_hp : float
var current_rpm : float
var normalized_rpm : float

func _ready() -> void:
	if power_curve != null:
		power_curve.bake()

func _process(delta: float) -> void:
	pass

func get_current_hp() -> float:
	return current_hp

func get_current_rpm() -> float:
	return current_rpm

func get_normalized_rpm() -> float:
	return normalized_rpm
	
func update_engine(throttle : float, delta : float) -> void:
	var target_hp : float = power_curve.sample(throttle) * max_hp
	current_hp = lerpf(current_hp, target_hp, delta * power_delay)
	
	var target_rpm : float = power_curve.sample(throttle) * max_rpm
	current_rpm = lerpf(current_rpm, target_rpm, delta * power_delay)
	normalized_rpm = inverse_lerp(0.0, max_rpm, current_rpm)
