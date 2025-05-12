extends Node2D

@onready var multiplayer_ui = $UI/Multiplayer

var players: int = 0

const PLAYER = preload("res://Scenes/Chara_Movement.tscn")
const ESPRIT = preload("res://Scenes/esprit.tscn")

var peer = ENetMultiplayerPeer.new()

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

func add_player(pid: int) -> void:
	if players == 0:
		var player = PLAYER.instantiate()
		player.name = str(pid)
		add_child(player)
