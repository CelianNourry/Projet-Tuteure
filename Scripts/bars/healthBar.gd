extends Bar

func _physics_process(delta: float) -> void:
	change_bar_color(self.value, delta)
	self.value = INFO.player.INFO.health
