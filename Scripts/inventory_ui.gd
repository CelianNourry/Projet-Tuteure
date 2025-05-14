extends Control

@onready var gridContainer: GridContainer = $GridContainer

var player: Node = null

func set_player(player_instance: Node) -> void:
	player = player_instance
	player.inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated()

func _on_inventory_updated() -> void:
	if player == null:
		return
	clear_grid_container()
	for item in player.inventory:
		var slot = Global.Inventory_slot_scene.instantiate()
		gridContainer.add_child(slot)
		if item != null:
			slot.set_item(item)
		else:
			slot.set_empty()

func clear_grid_container() -> void:
	while gridContainer.get_child_count() > 0:
		var child = gridContainer.get_child(0)
		gridContainer.remove_child(child)
		child.queue_free()
