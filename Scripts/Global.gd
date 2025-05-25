extends Node

@onready var PATHES: Dictionary[StringName, PackedScene] = {inventorySlot = preload("res://Scenes/inventory_slot.tscn")}

# Récupérer la racine du jeu depuis n'importe quel noeud
func get_game_root() -> Node:
	return get_tree().get_root().get_node("Game")

# Retourne le noeud du joueur demandé dans requestedPlayer
func get_player_node(requestedPlayer: String) -> Body:
	return get_tree().get_nodes_in_group("bodies").front() if requestedPlayer == "body" else get_tree().get_nodes_in_group("spirits").front()

func enforce_distance_from_host(inputVector: Vector2, position: Vector2, maxRange: float, delta: float) -> Vector2:
	var bodyNode: Body = self.get_player_node("body")
	var bodyPosition: Vector2 = bodyNode.global_position
	var bodyCurrentSpeed: float = bodyNode.INFO.currentSpeed

	# Prévoir la position à la prochaine frame
	var predictedPosition: Vector2 = position + inputVector.normalized() * bodyCurrentSpeed * delta
	var predictedDistance: float = predictedPosition.distance_to(bodyPosition)

	if predictedDistance > maxRange:
		# Si on sort du rayon autorisé, on force le déplacement vers l'hôte
		var vectorToHost: Vector2 = (bodyPosition - position).normalized()
		return vectorToHost * bodyCurrentSpeed
	
	return inputVector.normalized() * bodyCurrentSpeed

func generate_raycasts(node: Node, FOV, angleBetweenRays, maxViewDistance, enabled) -> void:
	var raysToGenerate: int = int(FOV / angleBetweenRays)

	for i in range(raysToGenerate):
		var ray: RayCast2D = RayCast2D.new()
		var angle : float= angleBetweenRays * (i - raysToGenerate / 2.0)
		ray.target_position = Vector2.UP.rotated(angle) * maxViewDistance
		ray.enabled = enabled
		node.add_child(ray)
	
func adjust_drop_position(position: Vector2) -> Vector2:
	var radius = 10
	var nearby_items = get_tree().get_nodes_in_group("Items")

	for item in nearby_items:
		if item is Node2D:
			if item.global_position.distance_to(position) < radius:
				var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
				position += random_offset
				break
	return position
	
@rpc("any_peer", "call_local")
func drop_item(item_data: Dictionary, drop_position: Vector2) -> void:
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
