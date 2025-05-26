extends StaticBody2D
class_name HVS
@onready var NODES: Dictionary[StringName, Node] = {
	sprite = $Sprite2D,
	stateIndicatorLight = $"State Indicator Light"
}
	
@export var TEXTURES: Dictionary[StringName, Texture2D] = {
	HVS_ON = preload("res://sprites/interactables/high voltage station - ON.png"),
	HVS_OFF = preload("res://sprites/interactables/high voltage station - OFF.png")
}

var _power: bool

func _ready() -> void:
	var root = Global.get_game_root()
	if root and root.INFO:
		self._power = root.INFO.power
		update_HVS_sprite()
	else:
		await get_tree().process_frame
		self._power = Global.get_game_root().INFO.power
		update_HVS_sprite()
	
func update_HVS_sprite() -> void:
	if self._power:
		NODES.sprite.texture = TEXTURES.HVS_ON
		NODES.stateIndicatorLight.color = Color("#ffff0096")
	else:
		NODES.sprite.texture = TEXTURES.HVS_OFF
		NODES.stateIndicatorLight.color = Color("#ca000d96")
	
func switch_power_state() -> void:
	self._power = !self._power
	Global.get_game_root().INFO.power = self._power
	update_HVS_sprite()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_HVS(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_HVS(null)
