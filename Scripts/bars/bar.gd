extends TextureProgressBar
class_name Bar

#region Informations
@onready var player: CharacterBody2D = $"../.."

var blinkTimer: float = 0.00

const blinkInterval: float = 1.00
const veryLowStamina: float = 15.00

	#region Colors
var veryLowProgressColor: Color
var lowProgressColor: Color
var highProgressColor: Color
	#endregion
#endregion

func change_bar_color(percentage: float, delta: float) -> void:
	if percentage > veryLowStamina:
		# Interpolation entre vert et rouge
		self.tint_progress = lowProgressColor.lerp(highProgressColor, clamp(percentage / 100.00, 0.00, 1.00))
		
	else:
		# Clignotement entre DARK_RED et BLACK si très faible pourcentage
		blinkTimer += delta
		self.tint_progress = veryLowProgressColor if blinkTimer < blinkInterval / 2 else Color.BLACK
		
		if blinkTimer > blinkInterval: blinkTimer = 0.00

func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
