extends Control

# Scene-Tree Node Reference
@onready var icon: Sprite2D = $InnerBorder/ItemIcon
@onready var quantityLabel: Label = $InnerBorder/ItemQuantity
@onready var detailsPannel: ColorRect = $DetailPanel
@onready var itemName: Label = $DetailPanel/ItemName
@onready var itemEffect: Label = $DetailPanel/ItemEffect
@onready var usagePannel: ColorRect = $UsagePannel

@onready var item: Dictionary = {}

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
	if item["effect"] != "":
		itemEffect.text = str(item["effect"])
	else:
		itemEffect.text = ""

func _on_use_button_pressed() -> void:
	usagePannel.visible = false
	if item != {} and item["effect"] != "":
		var player = Global.get_own_player_node()
		player.apply_item_effect(item)
		player.remove_item(item["name"], item["effect"])

func _on_drop_button_pressed() -> void:
	if item != {}:
		var player = Global.get_own_player_node()
		var drop_position = player.global_position
		var drop_offset = Vector2(0, 50).rotated(player.rotation)
		Global.drop_item.rpc(item, drop_position + drop_offset)
		player.remove_item(item["name"], item["effect"])
		usagePannel.visible = false
