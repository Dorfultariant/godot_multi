extends RigidBody3D

var explosion = preload("res://tanks/explosions/explosion.tscn")
var SPEED = 30.0
@onready var particles = $GPUParticles3D
#@onready var round = $
@onready var round_col = $CollisionShape3D
#@onready var audio_rocket_shoot = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()

func initialize():
	linear_velocity = transform.basis * Vector3(0, 0, SPEED)
	particles.emitting = true
	#audio_rocket_shoot.play()


func _on_body_entered(_body):
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	despawn()
	
func despawn():
	set_freeze_enabled(true)
	round_col.set_shape(null)
	round_col.hide()
	#rocket.hide()
	particles.emitting = false
	print("Rocket will despawn shortly")

func _on_timer_timeout():
	print("Rocket despawns")
	queue_free()
