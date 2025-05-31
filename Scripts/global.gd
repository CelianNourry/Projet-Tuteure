extends Node

#region PATHES
@onready var inventorySlot: Resource = preload("res://Scenes/inventory/slot.tscn")
#endregion

#region TEXT
const E_open: String = "E - Ouvrir"
const E_close: String = "E - Fermer"
const E_pickUp: String = "E - Ramasser"
const E_turnOn: String = "E - Allumer"
const E_turnOff: String = "E - Eteindre"
const L_unlock: String = "L - Deverouiller"
const L_lock: String = "L - Verouiller"
#endregion

#region Compass
enum compassDir {
	E = 0, NE = 1,
	N = 2, NW = 3,
	W = 4, SW = 5,
	S = 6, SE = 7
};

const HEADINGS: Array[String] = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]
#endregion

func vector_to_compass_dir(vector: Vector2) -> String:
	if vector == Vector2.ZERO:
		return "None"

	var angle := atan2(-vector.y, vector.x)
	var octant := int(round(8 * angle / (2 * PI) + 8)) % 8

	return HEADINGS[octant]
	
# Récupérer le noeud du jeu depuis n'importe quel noeud
func get_game_node() -> Game:
	return get_tree().get_root().get_node("Game") if get_tree().get_root().get_node("Game") != null else null

# Retourne le noeud du joueur demandé dans requestedPlayer
func get_player_node(requestedPlayer: String) -> CharacterBody2D:
	var requestedGroup: String
	match requestedPlayer:
		"body":
			requestedGroup = "bodies"
		"spirit":
			requestedGroup = "spirits"
		_:
			push_error("Wrong requested player. Choose between 'body' or 'spirit'")
			return null

	var collectedNodes: Array[Node] = get_tree().get_nodes_in_group(requestedGroup)
	
	return collectedNodes.front() if not collectedNodes.is_empty() else null

func enforce_distance_from_host(inputVector: Vector2, spiritSpeed: float, position: Vector2, maxRange: float, delta: float) -> Vector2:
	var bodyNode: Body = self.get_player_node("body")
	var bodyPosition: Vector2 = bodyNode.global_position
	var bodyCurrentSpeed: float = bodyNode.currentSpeed

	# Prévoir la position à la prochaine frame
	var predictedPosition: Vector2 = position + inputVector.normalized() * bodyCurrentSpeed * delta
	var predictedDistance: float = predictedPosition.distance_to(bodyPosition)

	if predictedDistance > maxRange:
		# Si on sort du rayon autorisé, on force le déplacement vers le Body
		return (bodyPosition - position).normalized() * bodyCurrentSpeed
	
	# Sinon, on garde la velocité initiale du Spirit
	return inputVector.normalized() * spiritSpeed
	
func cartesian_to_isometric(cartesian: Vector2) -> Vector2:
	return Vector2(cartesian.x - cartesian.y, (cartesian.x + cartesian.y) /2)

"""
# Inutilisé pour le moment
func rotate_vector(vec: Vector2, degrees: float) -> Vector2:
	var radians = deg_to_rad(degrees)
	var cos_angle = cos(radians)
	var sin_angle = sin(radians)
	return Vector2(
		vec.x * cos_angle - vec.y * sin_angle,
		vec.x * sin_angle + vec.y * cos_angle
	)
"""

func generate_raycasts(node: Node, FOV: float, angleBetweenRays: float, maxViewDistance: float, enabled: bool) -> void:
	var raysToGenerate: int = int(FOV / angleBetweenRays)

	for i in range(raysToGenerate):
		var ray: RayCast2D = RayCast2D.new()
		var angle: float = angleBetweenRays * (i - raysToGenerate / 2.0)
		ray.target_position = Vector2.UP.rotated(angle) * maxViewDistance
		ray.enabled = enabled
		node.add_child(ray)
	
func adjust_drop_position(position: Vector2) -> Vector2:
	var radius: float = 10.00
	var nearby_items: Array[Node] = get_tree().get_nodes_in_group("Items")

	for item: Item in nearby_items:
		if item.global_position.distance_to(position) < radius:
			var random_offset: Vector2 = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			position += random_offset
			break
	return position
	
func instanciate_item(itemData: Dictionary) -> Item:
	var instance: Item = load(itemData["scenePath"]).instantiate()
	instance.set_item_data(itemData)
	return instance
	
@rpc("any_peer", "call_local")
func drop_item(item_data: Dictionary, drop_position: Vector2) -> void:
	var item_scene: Resource = load(item_data["scenePath"])
	var item_instance: Item = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
