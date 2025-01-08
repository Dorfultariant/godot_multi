extends CharacterBody3D
# This is tow ammo character, which is user controllable to a position

var SPEED : float = 800.0
var ACCELERATION : float = 10.0
var TURNING_SPEED : float = 5.5 # in degrees
var DAMAGE : float = 400
# Global position of the target the TOW should hit
var target_transform
var explosion = load("res://tanks/scenes/explosion.tscn")
# Parent node in the node tree, add it in later.
var player_in_control
signal controlled_despawns

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var collision = get_last_slide_collision()
	if collision:
		collision_detected(collision)
	if target_transform:
		
		var target_position = target_transform.origin
		var new_transform = transform.looking_at(target_position, Vector3.UP, true)
		transform  = transform.interpolate_with(new_transform, TURNING_SPEED * delta)
	
	velocity = transform.basis * Vector3.BACK * delta * ACCELERATION * SPEED
	#velocity.z = transform.origin.z * SPEED * ACCELERATION * delta
	
	move_and_slide()

func set_player(player_rid : RID) -> void:
	player_in_control = player_rid

func update_target(target) -> void:
	target_transform = target

func collision_detected(_body) -> void:
	var W = get_tree().get_root()
	var E = explosion.instantiate()
	E.set_global_transform(get_global_transform())
	W.add_child(E)
	
	if _body.has_method("took_damage"):
		_body.took_damage(DAMAGE)
	
	emit_signal("controlled_despawns")

func despawn() -> void:
	var W = get_tree().get_root()
	$GPUParticles3D.stop_emiting()
	$GPUParticles3D.reparent(W)
	queue_free()
