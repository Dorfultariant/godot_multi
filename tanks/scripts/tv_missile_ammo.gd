extends CharacterBody3D


const SPEED = 1000.0
const TURN_SPEED = 1.0
const DAMAGE = 40.0

var timer : Timer
var player_in_control : bool = false
@onready var camera = $Camera3D
var explosion = load("res://tanks/scenes/explosion.tscn")

signal guided_despawns

func _ready() -> void:
	timer = Timer.new()
	add_sibling(timer)
	timer.wait_time = 10.0
	timer.timeout.connect(_on_timer_timeout)
	camera.make_current()
	timer.start()

func _input(event: InputEvent) -> void:
	if player_in_control and event is InputEventMouseMotion:
		rotation.y -= event.relative.x / Global.mouseXSensibility
		rotation.x -= -event.relative.y / Global.mouseYSensibility
		#rotation.y -= lerp(rotation.y, event.relative.x / Global.mouseXSensibility, TURN_SPEED*0.02)
		#rotation.x -= lerp(rotation.x, -event.relative.y / Global.mouseYSensibility, TURN_SPEED*0.02)

func _physics_process(delta: float) -> void:
	var collision = get_last_slide_collision()
	if collision:
		collision_detected(collision)
	
	velocity = transform.basis * Vector3.BACK * delta * SPEED * 10.0
	#velocity.z = transform.origin.z * SPEED * ACCELERATION * delta
	move_and_slide()

func player_make_current() -> void:
	player_in_control = true

func _on_timer_timeout() -> void:
	despawn()

func collision_detected(_body) -> void:
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	if _body.has_method("took_damage"):
		_body.took_damage(DAMAGE)
	despawn()

func despawn() -> void:
	Global.player_body[0].player_make_current()
	emit_signal("guided_despawns")
	var W = get_tree().get_root()
	$GPUParticles3D.stop_emiting()
	$GPUParticles3D.reparent(W)
	print("TV missile despawns now.")
	queue_free()
