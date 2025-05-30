extends Control

# Noeud du slot d'inventaire
@onready var NODES: Dictionary[StringName, Node] = {
	icon = $InnerBorder/ItemIcon,
	quantityLabel = $InnerBorder/ItemQuantity,
	detailsPannel = $DetailPanel,
	itemName = $DetailPanel/ItemName,
	itemDescription = $DetailPanel/ItemDescription,
	usagePannel = $UsagePannel
}

@onready var item: Dictionary = {}

func _on_item_button_pressed() -> void:
	if item != {}:
		NODES.usagePannel.visible = !NODES.usagePannel.visible

func _on_item_button_mouse_entered() -> void:
	if item != {}:
		NODES.detailsPannel.visible = true

func _on_item_button_mouse_exited() -> void:
	NODES.detailsPannel.visible = false

#Default empty slot
func set_empty() -> void:
	NODES.icon.texture = null
	NODES.quantityLabel.text = ""

func set_item(new_item: Dictionary) -> void:
	item = new_item
	if typeof(new_item["texture"]) == TYPE_STRING:
		NODES.icon.texture = load(new_item["texture"])
	else:
		NODES.icon.texture = new_item["texture"]
	NODES.quantityLabel.text = str(item["quantity"])
	NODES.itemName.text = str(item["name"])
	if item["description"] != "":
		NODES.itemDescription.text = str(item["description"])
	else:
		NODES.itemDescription.text = ""

func _on_use_button_pressed() -> void:
	NODES.usagePannel.visible = false
	if item != {}:
		var player = Global.get_player_node("body")
		Global.instanciate_item(item).use()
		player.remove_item(item["name"])

func _on_drop_button_pressed() -> void:
	if item != {}:
		var player = Global.get_player_node("body")
		var drop_position = player.global_position
		var drop_offset = Vector2(0, 20).rotated(player.rotation)
		Global.drop_item.rpc(item, drop_position + drop_offset)
		player.remove_item(item["name"])
		NODES.usagePannel.visible = false
