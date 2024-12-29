extends StaticBody3D

var health = 100
var linger_after_death = 60.0
var killed : bool = false
@onready var timer = $Timer

func took_damage(given_damage : float) -> void:
	if health - given_damage <= 0.0:
		if not killed:
			$AnimationPlayer.play("kill_explosion_1")
			killed = true
	else:
		health -= given_damage

func _on_animation_finished(anim_name: StringName) -> void:
	timer.wait_time = linger_after_death
	timer.start()

func _on_timer_timeout() -> void:
	queue_free()
