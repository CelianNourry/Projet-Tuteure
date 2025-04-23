extends Control

#Scene-Tree Node Reference
@onready var icon = $InnerBorder/ItemIcon
@onready var quantity_label = $InnerBorder/ItemQuantity
@onready var details_panel = $DetailPanel
@onready var item_name = $DetailPanel/ItemName
@onready var item_effect = $DetailPanel/ItemEffect
@onready var usage_pannel = $UsagePannel

#Slot item
var item = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_item_button_pressed():
	if item != null:
		usage_pannel.visible = !usage_pannel.visible

func _on_item_button_mouse_entered():
	if item != null:
		details_panel.visible = true

func _on_item_button_mouse_exited():
	details_panel.visible = false

#Default empty slot
func set_empty():
	icon.texture = null
	quantity_label.text = ""

func set_item(new_item):
	item = new_item
	icon.texture = new_item["texture"]
	quantity_label.text = str(item["quantity"])
	item_name.text = str(item["name"])
	if item["effect"] != "":
		item_effect.text = str(item["effect"])
	else:
		item_effect.text = ""

func _on_use_button_pressed():
	usage_pannel.visible = false
	if item != null and item["effect"] != "":
		if Global.player_node:
			Global.player_node.apply_item_effect(item)
			Global.player_node.remove_item(item["name"], item["effect"])
		else:
			print("Player couldn(t be found.)")

func _on_drop_button_pressed():
	if item != null:
		var drop_position = Global.player_node.global_position
		var drop_offset = Vector2(0, 50).rotated(Global.player_node.rotation)
		Global.drop_item(item, drop_position + drop_offset)
		Global.player_node.remove_item(item["name"], item["effect"])
		usage_pannel.visible = false
