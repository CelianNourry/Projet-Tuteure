class_name Door
extends StaticBody2D

@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var locked: bool

func interact_with_front_door() -> void:
	if locked:
		print("La porte est verrouilée")
	else:
		collisionShape.disabled = !collisionShape.disabled
	return
	
func interact_with_back_door(action: String) -> void:
	if action == "interact":
		interact_with_front_door()
	elif action == "lock":
		print("Porte deverouilée")
		locked != locked

func _on_front_body_entered(body: Node2D) -> void:
	if body.has_method("set_interactable_front_door"):
		body.set_interactable_front_door(self)

func _on_front_body_exited(body: Node2D) -> void:
	if body.has_method("set_interactable_front_door"):
		body.set_interactable_front_door(null)

func _on_back_body_entered(body: Node2D) -> void:
	if body.has_method("set_interactable_back_door"):
		body.set_interactable_back_door(self)

func _on_back_body_exited(body: Node2D) -> void:
	if body.has_method("set_interactable_back_door"):
		body.set_interactable_back_door(null)
