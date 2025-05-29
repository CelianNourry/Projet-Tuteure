extends Control

# Noeuds de l'UI d'inventaire
@onready var NODES: Dictionary[StringName, Node] = {
	player = null,
	gridContainer = $GridContainer
}

func set_player(playerInstance: Body) -> void:
	NODES.player = playerInstance
	NODES.player.inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated()

func _on_inventory_updated() -> void:
	if NODES.player == null:
		return
	clear_grid_container()
	for item in NODES.player.INFO.inventory:
		var slot: Control = Global.PATHES.inventorySlot.instantiate()
		NODES.gridContainer.add_child(slot)
		if item != null:
			slot.set_item(item)
		else:
			slot.set_empty()

func clear_grid_container() -> void:
	while NODES.gridContainer.get_child_count() > 0:
		var child = NODES.gridContainer.get_child(0)
		NODES.gridContainer.remove_child(child)
		child.queue_free()
