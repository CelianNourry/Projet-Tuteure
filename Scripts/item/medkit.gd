@tool
extends Item
class_name Medkit

# Informations du Kit de soin
const INFO_MEDKIT: Dictionary[StringName, Variant] = {
	name = "Kit de soin",
	description = "Utiliser le en cas de blessure.",
	texture = preload("res://Sprites/items/medkit.png"),
	scale = Vector2(1.010, 1.010),
	scenePath = "res://Scenes/items/medkit.tscn"
}

func _ready() -> void:
	INFO.name = INFO_MEDKIT.name
	INFO.description = INFO_MEDKIT.description
	INFO.texture = INFO_MEDKIT.texture
	INFO.scale = INFO_MEDKIT.scale
	INFO.scenePath = INFO_MEDKIT.scenePath
	
	initialize()

func use() -> void:
	Global.get_player_node("body").stopBleeding()
