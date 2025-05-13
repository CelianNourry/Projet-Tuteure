extends Node2D

@onready var multiplayer_ui = $UI/Multiplayer

const PLAYER = preload("res://Scenes/Chara_Movement.tscn")

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
	multiplayer_ui.hide()

func _on_join_pressed() -> void:
	peer.create_client("localhost", 4242)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()

func add_player(pid: int) -> void:
	var player = PLAYER.instantiate()
	player.name = str(pid)
	add_child(player)
	if pid == multiplayer.get_unique_id():
		player.add_to_group("players")
		
