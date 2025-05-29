@tool
extends Item
class_name Medkit

# Informations du Kit de soin
const INFO_MEDKIT: Dictionary[StringName, Variant] = {
	name = "Kit de soin",
	description = "Utiliser le en cas de blessure.",
	texture = preload("res://Sprites/items/medkit.png"),
	scenePath = "res://Scenes/items/medkit.tscn"
}

func _ready():
	INFO.name = INFO_MEDKIT.name
	INFO.description = INFO_MEDKIT.description
	INFO.texture = INFO_MEDKIT.texture
	INFO.scenePath = INFO_MEDKIT.scenePath
	sprite.texture = INFO.texture

# Arrete le saignemeent et met le regain de stamina a 2.00
func use(body: Body):
	body.NODES.bleeding.emitting = false
	body.INFO.idleStaminaGain = 2.00
