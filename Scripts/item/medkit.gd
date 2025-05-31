@tool
extends Item
class_name Medkit

func _ready() -> void:
	itemName = "Kit de soin"
	itemDescription = "Utiliser le en cas de blessure."
	itemTexture = preload("res://Sprites/items/medkit.png")
	itemScale = Vector2(1.010, 1.010)
	itemScenePath = "res://Scenes/items/medkit.tscn"
	
	initialize()

func use() -> void:
	Global.get_player_node("body").stop_bleeding()
