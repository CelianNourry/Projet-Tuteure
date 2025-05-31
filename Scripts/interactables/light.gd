extends StaticBody2D
class_name Light

#region Nodes
@onready var upperSprite: AnimatedSprite2D = $Sprite/Upper
@onready var light: PointLight2D = $PointLight2D
@onready var flickeringTimer: Timer = $"Flickering Timer"
@onready var flickeringArea: Area2D = $"Flickering Area2D"
#endregion

#region Informations
@export var _power: bool
@export var isFlickering: bool = false
#endregion

func _ready() -> void:
	var game: Game = Global.get_game_node()
	if game and game:
		self._power = game.power
		rpc("update_light_sprite")
	else:
		await get_tree().process_frame
		self._power = Global.get_game_node().power
		rpc("update_light_sprite")

func _physics_process(_delta: float) -> void:
	
	if isFlickering and not flickeringTimer.is_stopped():
		return 

	if isFlickering and flickeringTimer.is_stopped():
		flickeringTimer.start()
	elif not isFlickering and not flickeringTimer.is_stopped():
		flickeringTimer.stop()

@rpc("any_peer", "call_local")
func update_light_sprite() -> void:
	if self._power:
		upperSprite.animation = "ON"
		light.color = Color("#ffff1b")
	else:
		upperSprite.animation = "OFF"
		light.color = Color("#ffff1b00")

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
