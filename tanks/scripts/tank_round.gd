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

#func _physics_process(delta: float) -> void:
	#var collisions = get_colliding_bodies()
	#if collisions:
		#for col in collisions:
			#var body = col.get_collider()
			#if body:
				#print("Hit")
				#despawn()
				#hit_if_enemy(body, slide_collision)

func _on_body_entered(_body):
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	if _body.has_method("took_damage"):
		_body.took_damage(DAMAGE)
	despawn()
	
func despawn():
	
	queue_free()
	#set_freeze_enabled(true)
	#round_col.set_shape(null)
	#round_col.hide()
	##rocket.hide()
	#particles.emitting = false
	#print("Rocket will despawn shortly")

func _on_timer_timeout():
	print("Rocket despawns")
	queue_free()
