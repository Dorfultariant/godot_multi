extends CharacterBody3D


@export_range(50.0, 2000.0) var speed_cap : float = 1200.0
@export var speed_curve : Curve
@export_range(0.0, 10.0) var turn_speed = 0.9
@export_range(0.0, 200.0) var damage = 140.0
@export_range(0.0, 100.0) var despawn_wait_time = 10.0
const ORIENT_HORIZ_SPEED = 2.5

var despawn_timer : Timer
var player_in_control : bool = false
@onready var camera = $Camera3D
@export var explosion : PackedScene
var target_rotation : Vector3
signal guided_despawns

@export var damage_component : DamageComponent

func _ready() -> void:
	# Set camera
	camera.make_current()
	
	# Load the resource
	if explosion != null:
		print("Loading real explosion")
		ResourceLoader.load_threaded_get(explosion.to_string())
	else: # Backup
		print("Loading backup explosion")
		explosion.set_resource_path("res://tanks/scenes/explosion.tscn")
		ResourceLoader.load_threaded_get(explosion.to_string())
	
	# Set our current target to be our current rotation
	target_rotation = rotation
	speed_curve.bake()
	
	# All set, create despawn timer and start it
	despawn_timer = Timer.new()
	add_sibling(despawn_timer)
	despawn_timer.wait_time = despawn_wait_time
	despawn_timer.timeout.connect(_on_timer_timeout)
	despawn_timer.start()

func _input(event: InputEvent) -> void:
	if player_in_control and event is InputEventMouseMotion:
		target_rotation.y -= event.relative.x / Global.mouseXSensibility
		target_rotation.x -= -event.relative.y / Global.mouseYSensibility

func _physics_process(delta: float) -> void:
	var collision = get_last_slide_collision()
	if collision:
		collision_detected(collision)
	var normalized_time = (despawn_wait_time - despawn_timer.time_left) / despawn_wait_time #clamp(velocity.length() / speed_cap, 0.0, 1.0)
	var calc_velocity = speed_cap * speed_curve.sample(normalized_time)
	velocity = transform.basis * Vector3.BACK * delta * calc_velocity
	rotation.x = lerp_angle(rotation.x, target_rotation.x, turn_speed * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, turn_speed * delta)
	rotation.z = lerp_angle(rotation.z, deg_to_rad(0), ORIENT_HORIZ_SPEED * delta)
	
	if despawn_timer.time_left > 9.0:
		velocity.y -= delta * 40 * ProjectSettings.get_setting("physics/3d/default_gravity")
	#velocity.z = transform.origin.z * SPEED * ACCELERATION * delta
	move_and_slide()

func player_make_current() -> void:
	player_in_control = true

func _on_timer_timeout() -> void:
	despawn()

func collision_detected(_body) -> void:
	if damage_component:
		damage_component.deal_damage(_body, damage)
	despawn()

func despawn() -> void:
	ResourceLoader.load_threaded_get_status(explosion.to_string())
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	Global.player_body[0].player_make_current()
	emit_signal("guided_despawns")
	$GPUParticles3D.stop_emiting()
	$GPUParticles3D.reparent(W)
	print("TV missile despawns now.")
	queue_free()
