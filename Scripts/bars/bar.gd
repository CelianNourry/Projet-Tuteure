extends TextureProgressBar
class_name Bar

@onready var INFO: Dictionary[StringName, Variant] = {
	player = get_parent().get_parent(),
	blinkTimer = 0.00,
	blinkInterval = 1.00,
	lowStamina = 15.00
}

func change_bar_color(percentage: float, delta: float) -> void:
	if percentage > INFO.lowStamina:
		# Interpolation entre vert et rouge
		self.tint_progress = Color.RED.lerp(Color.GREEN, clamp(percentage / 100.00, 0.00, 1.00))
		
	else:
		# Clignotement entre DARK_RED et BLACK si très faible pourcentage
		INFO.blinkTimer += delta
		self.tint_progress = Color.DARK_RED if INFO.blinkTimer < INFO.blinkInterval / 2 else Color.BLACK
		
		if INFO.blinkTimer > INFO.blinkInterval: INFO.blinkTimer = 0.00

func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
