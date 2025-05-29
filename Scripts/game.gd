extends Node2D
class_name Game

# Noeuds du jeu
@onready var NODES: Dictionary[StringName, Node] = {
	multiplayerUI = $UI/Multiplayer,
	floor1 = $"Floors/Floor 1"
	}

# Variables en rapport avec le multijoueur
@onready var MULTIPLAYER: Dictionary[StringName, Variant] = {
	peer = ENetMultiplayerPeer.new(),
	playerCount = 0,
	maxPlayersAllowed = 2,
}

# Chemins vers d'autres scènes
const PATHES: Dictionary[StringName, PackedScene] = {
	body = preload("res://Scenes/characters/playables/body.tscn"),
	spirit = preload("res://Scenes/characters/playables/spirit.tscn")
	}

@onready var INFO: Dictionary[StringName, Variant] = {
	power = true,
}

"""
NOTE A MOI-MEME :
	La propriete spawn_path du MultiplayerSpawner doit ABSOLUMENT etre mise au noeud où les scènes
	sont censées spawner. En l'occurence mes scènes body.tscn et spirit.tscn spawn sur le Floor 1
	et non le root.
	Aussi, dans "Auto Spawn List, il faut absolument mettre les scènes des joueurs en tant qu'élément,
	sinon ils ne spawnent pas
"""

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
	await get_tree().process_frame
	if MULTIPLAYER.playerCount < MULTIPLAYER.maxPlayersAllowed:
		var player: CharacterBody2D = PATHES.body.instantiate() if pid == multiplayer.get_unique_id() else PATHES.spirit.instantiate()
		player.name = str(pid)
		NODES.floor1.add_child(player)
		return true
	return false
