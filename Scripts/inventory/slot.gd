extends Control
class_name Slot

#region Nodes
@onready var icon: Sprite2D = $InnerBorder/ItemIcon
@onready var quantityLabel: Label = $InnerBorder/ItemQuantity
@onready var detailsPannel: ColorRect = $DetailPanel
@onready var itemName: Label = $DetailPanel/ItemName
@onready var itemDescription: Label = $DetailPanel/ItemDescription
@onready var usagePannel: ColorRect = $UsagePannel
#endregion

#region Information
@onready var item: Dictionary = {}
#endregion

func _on_item_button_pressed() -> void:
	if item != {}:
		usagePannel.visible = !usagePannel.visible

func _on_item_button_mouse_entered() -> void:
	if item != {}:
		detailsPannel.visible = true

func _on_item_button_mouse_exited() -> void:
	detailsPannel.visible = false

#Default empty slot
func set_empty() -> void:
	icon.texture = null
	quantityLabel.text = ""

func set_item(new_item: Dictionary) -> void:
	item = new_item
	if typeof(new_item["texture"]) == TYPE_STRING:
		icon.texture = load(new_item["texture"])
	else:
		icon.texture = new_item["texture"]
	quantityLabel.text = str(item["quantity"])
	itemName.text = str(item["name"])
	if item["description"] != "":
		itemDescription.text = str(item["description"])
	else:
		itemDescription.text = ""

func _on_use_button_pressed() -> void:
	usagePannel.visible = false
	if item != {}:
		var player: Body = Global.get_player_node("body")
		Global.instanciate_item(item).use()
		player.remove_item(item["name"])

func _on_drop_button_pressed() -> void:
	if item != {}:
		var player: Body = Global.get_player_node("body")
		var drop_position: Vector2 = player.global_position
		var drop_offset: Vector2 = Vector2(0, 20).rotated(player.rotation)
		Global.drop_item.rpc(item, drop_position + drop_offset)
		player.remove_item(item["name"])
		usagePannel.visible = false
