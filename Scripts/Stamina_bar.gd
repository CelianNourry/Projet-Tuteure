extends TextureProgressBar

# Noeud du parent, qui est censé etre le joueur
@onready var player: Node2D = get_parent()

@onready var blinkTimer: float
const blinkInterval: float = 1.0
const lowStamina: float = 15.00

func _ready():
	# Cache la barre si ce joueur n'est pas sous notre contrôle
	if player.HOST and player.is_multiplayer_authority():
		self.visible = true
		
func change_bar_color(stamina: float, delta: float) -> void:
	if stamina > 15:
		# Normalise la stamina entre 0 et 1
		var t = clamp(stamina / 100.0, 0.0, 1.0)

		# Interpolation entre vert et rouge
		self.tint_progress = Color.RED.lerp(Color.GREEN, t)
		
	else:
		# Clignotement si très faible stamina
		blinkTimer += delta
		if blinkTimer < blinkInterval / 2:
			self.tint_progress = Color.DARK_RED
		else:
			self.tint_progress = Color.BLACK

		if blinkTimer > blinkInterval:
			blinkTimer = 0.0
			
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Change la progression de la barre selon la stamina du joueur
		self.value = player.STAMINA
		change_bar_color(self.value, delta)
