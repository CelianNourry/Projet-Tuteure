extends TextureProgressBar

# Noeud du parent, qui est censé etre le joueur
@onready var player: Node2D = get_parent()

@onready var blinkTimer: float
const blinkInterval: float = 1.00
const lowStamina: float = 15.00
		
func change_bar_color(stamina: float, delta: float) -> void:
	if stamina > 15.00:
		# Normalise la stamina entre 0 et 1
		var t = clamp(stamina / 100.00, 0.00, 1.00)

		# Interpolation entre vert et rouge
		self.tint_progress = Color.RED.lerp(Color.GREEN, t)
		
	else:
		# Clignotement entre DARK_RED et BLACK si très faible stamina
		blinkTimer += delta
		self.tint_progress = Color.DARK_RED if blinkTimer < blinkInterval / 2 else Color.BLACK

		if blinkTimer > blinkInterval:
			blinkTimer = 0.00
			
func _physics_process(delta: float) -> void:
	# Change la progression de la barre selon la stamina du joueur
	self.value = player.INFO.stamina
	change_bar_color(self.value, delta)
