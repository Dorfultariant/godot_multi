extends GPUParticles3D

@onready var tank_parent = get_parent()

func _ready() -> void:
	emitting = false

func _process(delta: float) -> void:
	var speed = tank_parent.velocity.length()
	if speed >= 1.0:
		emitting = true
	else:
		emitting = false
