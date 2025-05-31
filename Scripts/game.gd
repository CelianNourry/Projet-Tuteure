extends Node2D
class_name Game

#region Nodes
@onready var multiplayerUI: Control = $UI/Multiplayer
@onready var floor1: TileMapLayer = $"Floors/Floor 1"
#endregion

#region Multiplayer
@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var playerCount: int = 0
const maxPlayersAllowed: int = 2
#endregion

#region Pathes
const body: Resource = preload("res://Scenes/characters/playables/body.tscn")
const spirit: Resource = preload("res://Scenes/characters/playables/spirit.tscn")
#endregion

#region Informations
@export var power: bool = true
#endregion

"""
NOTE A MOI-MEME :
	La propriete spawn_path du MultiplayerSpawner doit ABSOLUMENT etre mise au noeud où les scènes
	sont censées spawner. En l'occurence mes scènes body.tscn et spirit.tscn spawn sur le Floor 1
	et non le root.
	Aussi, dans "Auto Spawn List, il faut absolument mettre les scènes des joueurs en tant qu'élément,
	sinon ils ne spawnent pas
"""

func _on_host_pressed() -> void:
	peer.create_server(4242)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid: int) -> void:
			add_player(pid)
			print("Pair " + str(pid) + " a rejoint la partie !")
	)
	# PID of the host
	add_player(multiplayer.get_unique_id())
	multiplayerUI.hide()

func _on_join_pressed() -> void:
	peer.create_client("localhost", 4242)
	multiplayer.multiplayer_peer = peer
	multiplayerUI.hide()

# Si le joueur est l'hote, il est ajouté dans la scène en tant que Body, sinon Spirit. Retourne true tant que le nombre de joueurs connectés ne dépasse pas le nombre maximum de joueurs autorisés dans la partie
func add_player(pid: int) -> bool:
	await get_tree().process_frame
	if playerCount < maxPlayersAllowed:
		var player: CharacterBody2D = body.instantiate() if pid == multiplayer.get_unique_id() else spirit.instantiate()
		player.name = str(pid)
		floor1.add_child(player)
		return true
	return false
