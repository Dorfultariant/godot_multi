extends Control

@export var ip : String = "127.0.0.1"
@export var port : int = 45123

@export var MAX_CLIENTS : int = 10

@onready var IP_text : LineEdit = $PanelContainer/MarginContainer/GridContainer/IP
@onready var Port_text : LineEdit = $PanelContainer/MarginContainer/GridContainer/Port 
@onready var create_server_btn : Button = $PanelContainer/MarginContainer/GridContainer/BCreate_Server
@onready var join_server_btn : Button = $PanelContainer/MarginContainer/GridContainer/BJoin_Server
@onready var name_tag : LineEdit = $PanelContainer/MarginContainer/GridContainer/Nametag


var peer : ENetMultiplayerPeer = null

@onready var world : PackedScene = preload("res://testing/maps/test_world_2.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _connected_to_server():
	print("Connected to server")
	send_player_information.rpc_id(1, name_tag.text, multiplayer.get_unique_id())

func _connection_failed():
	print("Connection to server failed")

func _player_connected(id):
	print("Player connection: ", id)

func _player_disconnected(id):
	print("Player disconnected: ", id)

@rpc("any_peer")
func send_player_information(name, id):
	# Check wether the player information
	# 	 is already stored in the players Dict
	if !Global.players.has(id):
		Global.players[id] = {
			"name": name,
			"id" : id
		}
		
	if multiplayer.is_server():
		for i in Global.players:
			send_player_information.rpc(Global.players[i].name, i)
	
	
@rpc("any_peer", "call_local", "unreliable")
func start_game():
	#var scene = world.instantiate()
	get_tree().change_scene_to_packed(world)
	
func _on_b_create_server_pressed():
	join_server_btn.hide()
	if IP_text.text.is_valid_ip_address():
		if Port_text.text.is_valid_int():
			port = Port_text.text.to_int()
			ip = IP_text.text
		else:
			print("Invalid port")
			print("Using default ", port)
	else:
		print("Invalid IPV4 Address")
		print("Using default ", ip)
	
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		print("Failed to create server")
		print(err)
		return
	#peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Server created, waiting for players...")
	send_player_information(name_tag.text, multiplayer.get_unique_id())

func _on_b_join_server_pressed():
	create_server_btn.hide()
	
	if IP_text.text.is_valid_ip_address():
		if Port_text.text.is_valid_int():
			ip = IP_text.text
			port = Port_text.text.to_int()
		else:
			print("Invalid port number")
			print("Using default ", port)
	else:
		print("Invalid IPV4 Address")
		print("Using default ", ip)
	
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	
	if (err != OK):
		print("Error while joining...")
		print(err)
		return
	#peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Client Created")


func _on_start_game_pressed() -> void:
	print("Staring game")
	start_game.rpc()
