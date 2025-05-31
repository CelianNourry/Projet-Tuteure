extends Bar
class_name Stamina_Bar

func _ready() -> void:
	veryLowProgressColor = Color.DARK_RED
	lowProgressColor = Color.RED
	highProgressColor = Color.GREEN
	
func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = player.stamina # La variable que la barre traque
