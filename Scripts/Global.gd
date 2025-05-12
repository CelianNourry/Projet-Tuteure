extends Node

@onready var Inventory_slot_scene = preload("res://Scenes/inventory_slot.tscn")

func _ready():
	pass
	
func adjust_drop_position(position):
	var radius = 10
	var nearby_items = get_tree().get_nodes_in_group("Items")

	for item in nearby_items:
		# Vérifiez que l'objet dans le groupe "Items" est un Node2D
		if item is Node2D:
			if item.global_position.distance_to(position) < radius:
				var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
				position += random_offset
				break
	return position
	
@rpc("any_peer", "call_local")
func drop_item(item_data, drop_position):
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
	
