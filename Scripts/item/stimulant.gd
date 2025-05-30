@tool
extends Item
class_name Stimulant

# Informations du Stimulant
const INFO_STIMULANT: Dictionary[StringName, Variant] = {
	name = "Stimulant",
	description = "Donne un boost des capacités cognitives.",
	texture = preload("res://Sprites/items/stimulant.png"),
	scale = Vector2(0.100, 0.100),
	scenePath = "res://Scenes/items/stimulant.tscn",
	powerGrant = 20.00
}

func _ready() -> void:
	INFO.name = INFO_STIMULANT.name
	INFO.description = INFO_STIMULANT.description
	INFO.texture = INFO_STIMULANT.texture
	INFO.scale = INFO_STIMULANT.scale
	INFO.scenePath = INFO_STIMULANT.scenePath
	
	initialize()

func use() -> void:
	if Global.get_player_node("spirit") != null:
		Global.get_player_node("spirit").rpc("add_power", INFO_STIMULANT.powerGrant)
	else:
		push_warning("Cannot use %s because there is no spirit in game" % [self])
