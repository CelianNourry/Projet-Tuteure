extends Node2D

@onready var NODES: Dictionary[StringName, Node] = {multiplayerUI = $UI/Multiplayer}
@onready var MULTIPLAYER: Dictionary[StringName, MultiplayerPeer] = {peer = ENetMultiplayerPeer.new()}
const PATHES: Dictionary[StringName, PackedScene] = {
	body = preload("res://Scenes/body.tscn"),
	spirit = preload("res://Scenes/spirit.tscn")
	}

func _on_host_pressed() -> void:
	MULTIPLAYER.peer.create_server(4242)
	multiplayer.multiplayer_peer = MULTIPLAYER.peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			add_player(pid)
			print("Pair " + str(pid) + " a rejoint la partie !")
	)
	# PID of the host
	add_player(multiplayer.get_unique_id())
	NODES.multiplayerUI.hide()

func _on_join_pressed() -> void:
	MULTIPLAYER.peer.create_client("localhost", 4242)
	multiplayer.multiplayer_peer = MULTIPLAYER.peer
	NODES.multiplayerUI.hide()

func add_player(pid: int) -> void:
	if pid == multiplayer.get_unique_id():
		var body: Body = PATHES.body.instantiate()
		body.name = str(pid)
		add_child(body)
	else:
		var spirit: Spirit = PATHES.spirit.instantiate()
		spirit.name = str(pid)
		add_child(spirit)
