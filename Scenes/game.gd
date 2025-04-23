extends Node2D

@onready var multiplayer_ui = $UI/Multiplayer

var players := {}

const PLAYER = preload("res://Scenes/Chara_Movement.tscn")
var peer =  ENetMultiplayerPeer.new()

func _on_host_pressed() -> void:
	peer.create_server(4242)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " as joined the game")
			add_player(pid)
	)
	# PID of the host
	add_player(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed() -> void:
	peer.create_client("localhost", 4242)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	player.set_multiplayer_authority(pid)
	player.add_to_group("players")
	add_child(player)
