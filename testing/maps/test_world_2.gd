extends Node3D

@export var PlayerScene : PackedScene = preload("res://tanks/scenes/ifv.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var idx = 0 
	print("Size of players dict: ", Global.players.size())
	var spwns = get_tree().get_nodes_in_group("Player_spawn_grp")
	var spwn_cnt = spwns.size()
	for i in Global.players:
		var curr = PlayerScene.instantiate()
		curr.name = str(Global.players[i].id)
		add_child(curr)
		curr.global_position = spwns[idx].global_position
		
		idx += 1 if idx < spwn_cnt else 0
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
