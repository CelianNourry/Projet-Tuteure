extends Node2D

# Noeuds du jeu
@onready var NODES: Dictionary[StringName, Node] = {multiplayerUI = $UI/Multiplayer}

# Variables en rapport avec le multijoueur
@onready var MULTIPLAYER: Dictionary[StringName, Variant] = {
	peer = ENetMultiplayerPeer.new(),
	playerCount = 0,
	maxPlayersAllowed = 2
}

# Chemins vers d'autres scènes
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

# Si le joueur est l'hote, il est ajouté dans la scène en tant que Body, sinon Spirit. Retourne true tant que le nombre de joueurs connectés ne dépasse pas le nombre maximum de joueurs autorisés dans la partie
func add_player(pid: int) -> bool:
	if MULTIPLAYER.playerCount < MULTIPLAYER.maxPlayersAllowed:
		var player: CharacterBody2D = PATHES.body.instantiate() if pid == multiplayer.get_unique_id() else PATHES.spirit.instantiate()
		player.name = str(pid)
		add_child(player)
		return true
	return false
