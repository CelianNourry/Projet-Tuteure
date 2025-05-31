@tool
extends Item
class_name Stimulant

#region Informations
const powerGrant: float = 20.00
#endregion

func _ready() -> void:
	itemName = "Stimulant"
	itemDescription = "Donne un boost des capacités cognitives."
	itemTexture = preload("res://Sprites/items/stimulant.png")
	itemScale = Vector2(0.100, 0.100)
	itemScenePath = "res://Scenes/items/stimulant.tscn"
	
	initialize()

func use() -> void:
	if Global.get_player_node("spirit") != null:
		Global.get_player_node("spirit").rpc("add_power", powerGrant)
	else:
		push_warning("Cannot use %s because there is no spirit in game" % [self])
