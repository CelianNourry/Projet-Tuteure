extends TextureProgressBar

var BLACK = Color(0.05, 0.05, 0.05, 1)
var RED_COLOR = Color(0.6, 0.13, 0.13)
var GREEN_COLOR = Color(0, 0.66, 0.09)
var GREEN_YELLOW = Color(0.678431, 1, 0.184314, 1)
var YELLOW = Color(1, 1, 0, 1)
var DARK_ORANGE = Color(1, 0.54902, 0, 1)

@onready var player = get_node("../../Player")
var blink_timer = 0.0
var blink_interval = 1.0

func _physics_process(delta):
	if !is_multiplayer_authority():
		return
		
	$"./".value = player.STAMINA
	
	if player.STAMINA > 80:
		self.tint_progress = GREEN_COLOR
		blink_timer = 0.0
	elif player.STAMINA > 60:
		self.tint_progress = GREEN_YELLOW
		blink_timer = 0.0
	elif player.STAMINA > 35:
		self.tint_progress = YELLOW
		blink_timer = 0.0
	elif player.STAMINA > 25:
		self.tint_progress = DARK_ORANGE
		blink_timer = 0.0
	else:
		blink_timer += delta
		if blink_timer < blink_interval / 2:
			self.tint_progress = RED_COLOR
		else:
			self.tint_progress = BLACK
		
		if blink_timer > blink_interval:
			blink_timer = 0.0
