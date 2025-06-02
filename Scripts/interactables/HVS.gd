extends StaticBody2D
class_name HVS

#region Nodes
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stateIndicatorLight: PointLight2D = $"State Indicator Light"
#endregion

#region Informations
var _power: bool
#endregion

func _ready() -> void:
	var game: Game = Global.get_game_node()
	if game:
		self._power = game.power
		rpc("update_HVS_sprite")
	else:
		await get_tree().process_frame
		self._power = Global.get_game_node().power
		rpc("update_HVS_sprite")

@rpc("any_peer", "call_local")
func update_HVS_sprite() -> void:
	if self._power:
		animatedSprite.animation = "ON"
		stateIndicatorLight.color = Color("#ffff0096")
	else:
		animatedSprite.animation = "OFF"
		stateIndicatorLight.color = Color("#ca000d96")

@rpc("any_peer", "call_local")
func switch_power_state() -> void:
	self._power = !self._power
	Global.get_game_node().power = self._power
	rpc("update_HVS_sprite")
	
	# Eteint toutes les lumières
	for light: Light in get_tree().get_nodes_in_group("lights"):
		light.switch_power_state()
	for door: Door in get_tree().get_nodes_in_group("doors"):
		if door.electric: door.switch_electric_state()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body is Body or body is Spirit) and body.is_multiplayer_authority():
		body.set_interactable_HVS(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if (body is Body or body is Spirit) and body.is_multiplayer_authority():
		body.set_interactable_HVS(null)
