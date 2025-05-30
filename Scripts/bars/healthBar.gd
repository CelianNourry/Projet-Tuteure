extends Bar
class_name Health_Bar

@onready var INFO_HEALTH_BAR: Dictionary[StringName, Variant] = {
	veryLowProgressColor = Color.DARK_RED,
	lowProgressColor = Color.RED,
	highProgressColor = Color.GREEN
}

func _ready():
	INFO.veryLowProgressColor = INFO_HEALTH_BAR.veryLowProgressColor
	INFO.lowProgressColor = INFO_HEALTH_BAR.lowProgressColor
	INFO.highProgressColor = INFO_HEALTH_BAR.highProgressColor
	
func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = INFO.player.INFO.health # La variable que la barre traque
