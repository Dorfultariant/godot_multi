extends RigidBody3D

var explosion = preload("res://tanks/scenes/explosion.tscn")
var SPEED = 60.0
var damage = 51.0
@onready var particles = $GPUParticles3D
#@onready var round = $
@onready var round_col = $CollisionShape3D
@export var damage_component : DamageComponent
#@onready var audio_rocket_shoot = $AudioStreamPlayer3D
signal ammo_hits

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()

func initialize():
	linear_velocity = transform.basis * Vector3(0, 0, SPEED)
	particles.emitting = true
	#audio_rocket_shoot.play()

func _on_body_entered(_body):
	emit_signal("ammo_hits", _body)
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	# Add better way to signal the health updates. Can be done with signals
	# (i.e. this node noticing a hit, informs to body to emit a "damage taken" signal)
	if damage_component:
		damage_component.deal_damage(_body, damage)
	
	despawn()
	
func despawn() -> void:
	if is_instance_valid(particles) != false and particles == null:
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
