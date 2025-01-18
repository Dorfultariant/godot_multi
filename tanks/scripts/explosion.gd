extends StaticBody3D

@onready var timer = $Timer
@onready var particles = $GPUParticles3D


func _ready() -> void:
	timer.wait_time = particles.lifetime
	timer.start()
	
	

func _on_timer_timeout() -> void:
	queue_free()
