extends Control

signal start_pressed()
signal host_pressed()
signal settings_pressed()
signal quit_pressed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_game_pressed() -> void:
	start_pressed.emit() # Replace with function body.


func _on_host_game_pressed() -> void:
	host_pressed.emit()

func _on_settings_pressed() -> void:
	settings_pressed.emit()

func _on_quit_pressed() -> void:
	quit_pressed.emit()
