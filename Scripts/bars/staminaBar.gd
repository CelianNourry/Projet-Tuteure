extends Bar
class_name Stamina_Bar

@onready var INFO_STAMINA_BAR: Dictionary[StringName, Variant] = {
	veryLowProgressColor = Color.DARK_RED,
	lowProgressColor = Color.RED,
	highProgressColor = Color.GREEN,
}

func _ready():
	INFO.veryLowProgressColor = INFO_STAMINA_BAR.veryLowProgressColor
	INFO.lowProgressColor = INFO_STAMINA_BAR.lowProgressColor
	INFO.highProgressColor = INFO_STAMINA_BAR.highProgressColor
	
func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = INFO.player.INFO.stamina # La variable que la barre traque
