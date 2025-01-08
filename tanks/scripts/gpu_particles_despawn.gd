extends GPUParticles3D

func stop_emiting() -> void:
	emitting = false
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime * 1.01 # add some extra
	timer.connect("timeout", _on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	queue_free()
