extends Bar
class_name Power_Bar

@onready var INFO_POWER_BAR: Dictionary[StringName, Variant] = {
	veryLowProgressColor = Color.LIGHT_BLUE,
	lowProgressColor = Color.LIGHT_BLUE,
	highProgressColor = Color.DARK_BLUE
}

func _ready():
	INFO.veryLowProgressColor = INFO_POWER_BAR.veryLowProgressColor
	INFO.lowProgressColor = INFO_POWER_BAR.lowProgressColor
	INFO.highProgressColor = INFO_POWER_BAR.highProgressColor
	
func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = INFO.player.INFO.power # La variable que la barre traque
