extends Node

@onready var PATHES: Dictionary[StringName, PackedScene] = {inventorySlot = preload("res://Scenes/inventory_slot.tscn")}
	
func get_own_player_node() -> Node:
	for node in get_tree().get_nodes_in_group("players"):
		if node.get_multiplayer_authority() == multiplayer.get_unique_id():
			return node
	return null
	
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
