extends Bar
class_name Power_Bar

func _ready() -> void:
	veryLowProgressColor = Color.LIGHT_BLUE
	lowProgressColor = Color.LIGHT_BLUE
	highProgressColor = Color.DARK_BLUE
	
func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = player.power # La variable que la barre traque
