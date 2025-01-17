extends Control

@onready var FPS = $FPS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	FPS.text = "%.1f" % (Engine.get_frames_per_second())
	

func set_speed_text(speed_text : String) -> void:
	$InfoCenter/Speed.text = speed_text

func set_gear_text(gear_text : String) -> void:
	$InfoCenter/Gear.text = gear_text
