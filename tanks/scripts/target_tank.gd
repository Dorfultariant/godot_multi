extends StaticBody3D

var linger_after_death = 60.0
var killed : bool = false
@onready var timer = $Timer

@export var health_component : HealthComponent 

func _ready() -> void:
	if is_instance_valid(health_component) and health_component != null:
		health_component.connect("health_reached_min", play_death_animation)

func play_death_animation() -> void:
	if killed:
		return
	$AnimationPlayer.play("kill_explosion_1")
	killed = true
	
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "kill_explosion_1":
		timer.wait_time = linger_after_death
		timer.start()

func _on_timer_timeout() -> void:
	queue_free()
