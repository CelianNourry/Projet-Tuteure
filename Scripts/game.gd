extends Node2D

@onready var multiplayerUI: Control = $UI/Multiplayer

var PLAYER = preload("res://Scenes/Chara_Movement.tscn")

var peer = ENetMultiplayerPeer.new()

func _on_host_pressed() -> void:
	peer.create_server(4242)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			add_player(pid)
			print("Peer " + str(pid) + " as joined the game")
	)
	# PID of the host
	add_player(multiplayer.get_unique_id())
	multiplayerUI.hide()

func _on_join_pressed() -> void:
	peer.create_client("localhost", 4242)
	multiplayer.multiplayer_peer = peer
	multiplayerUI.hide()

func add_player(pid: int) -> void:
	var player = PLAYER.instantiate()
	player.name = str(pid)
	add_child(player)
	
	player.add_to_group("players")
