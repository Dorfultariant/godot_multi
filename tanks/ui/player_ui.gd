extends Control

@onready var FPS = $FPS


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	FPS.text = "%.1f" % (Engine.get_frames_per_second())
