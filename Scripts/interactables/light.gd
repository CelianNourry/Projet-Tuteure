extends StaticBody2D
class_name Light

@onready var NODES: Dictionary[StringName, Node] = {
	upperSprite = $Sprite/Upper,
	light = $PointLight2D,
	flickeringTimer = $"Flickering Timer",
	flickeringArea = $"Flickering Area2D"
}

@export var _power: bool
@export var isFlickering: bool = false

func _ready() -> void:
	var game: Game = Global.get_game_node()
	if game and game.INFO:
		self._power = game.INFO.power
		rpc("update_light_sprite")
	else:
		await get_tree().process_frame
		self._power = Global.get_game_node().INFO.power
		rpc("update_light_sprite")

func _physics_process(_delta: float) -> void:
	
	if isFlickering and not NODES.flickeringTimer.is_stopped():
		return 

	if isFlickering and NODES.flickeringTimer.is_stopped():
		NODES.flickeringTimer.start()
	elif not isFlickering and not NODES.flickeringTimer.is_stopped():
		NODES.flickeringTimer.stop()

@rpc("any_peer", "call_local")
func update_light_sprite() -> void:
	if self._power:
		NODES.upperSprite.animation = "ON"
		NODES.light.color = Color("#ffff1b")
	else:
		NODES.upperSprite.animation = "OFF"
		NODES.light.color = Color("#ffff1b00")

func switch_power_state() -> void:
	self._power = !self._power
	rpc("update_light_sprite")

func _on_flickering_timer_timeout() -> void:
	switch_power_state()

func _on_flickering_area_2d_body_entered(body: Node2D) -> void:
	if body is Spirit:
		isFlickering = true
		
func _on_flickering_area_2d_body_exited(body: Node2D) -> void:
	if body is Spirit:
		isFlickering = false
