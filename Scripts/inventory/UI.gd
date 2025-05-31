extends Control

#region Nodes
@onready var player: Body = null
@onready var gridContainer: GridContainer = $GridContainer
#endregion

func set_player(playerInstance: Body) -> void:
	player = playerInstance
	player.inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated()

func _on_inventory_updated() -> void:
	if player == null:
		return
	clear_grid_container()
	for item: Variant in player.inventory:
		var slot: Control = Global.inventorySlot.instantiate()
		gridContainer.add_child(slot)
		if item != null:
			slot.set_item(item)
		else:
			slot.set_empty()

func clear_grid_container() -> void:
	while gridContainer.get_child_count() > 0:
		var child: Slot = gridContainer.get_child(0)
		gridContainer.remove_child(child)
		child.queue_free()
