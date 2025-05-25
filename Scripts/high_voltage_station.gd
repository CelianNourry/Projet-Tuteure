extends StaticBody2D
class_name HVS
@onready var NODES: Dictionary[StringName, Node] = {
	sprite = $Sprite2D
}
	
@export var TEXTURES: Dictionary[StringName, Texture2D] = {
	HVS_ON = preload("res://sprites/interactables/high voltage station - ON.png"),
	HVS_OFF = preload("res://sprites/interactables/high voltage station - OFF.png")
}

@export var power: bool = true
	
func switch_power_state() -> void:
	NODES.sprite.texture = TEXTURES.HVS_ON if self.power else TEXTURES.HVS_OFF
	self.power = !self.power
	Global.get_game_root().power = self.power

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_HVS(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_HVS(null)
