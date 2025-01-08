extends RigidBody3D

var explosion = preload("res://tanks/scenes/explosion.tscn")
var SPEED = 60.0
var DAMAGE = 51.0
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
	
	if _body.has_method("took_damage"):
		_body.took_damage(DAMAGE)
	despawn()
	
func despawn() -> void:
	if get_node("GPUParticles3D") == null:
		if is_queued_for_deletion():
			return
		else:
			queue_free()
			return
	var W = get_tree().get_root()
	particles.stop_emiting()
	
	# Moves the particles to the ROOT, so we can despawn the projectile without affecting the particles (sudden disappear)
	particles.reparent(W)
	print("Despawning ", get_rid())
	queue_free()

func _on_timer_timeout():
	
	despawn()
