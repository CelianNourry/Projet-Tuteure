class_name Door
extends StaticBody2D

# Noeuds de la porte
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D
}

# Informations de la porte
@export var INFO: Dictionary[StringName, bool] = {
	locked = true,
	seenByHost = false
}

func interact_with_front_door() -> void:
	if INFO.locked:
		print("La porte est verrouilée !")
	else:
		NODES.collisionShape.disabled = !NODES.collisionShape.disabled
	
func interact_with_back_door(action: String) -> void:
	match action:
		"interact":
			interact_with_front_door()
		"lock":
			INFO.locked = !INFO.locked
			print("Porte %s" % ("verrouillée" if INFO.locked else "déverrouillée"))

func _on_front_body_entered(body: Node2D) -> void:
	if body is Player and body.is_multiplayer_authority():
		print("Joueur %s entré dans la face d'une porte" % [body.name])
		body.set_interactable_front_door(self)

func _on_front_body_exited(body: Node2D) -> void:
	if body is Player and body.is_multiplayer_authority():
		print("Joueur %s sortit de la face d'une porte" % [body.name])
		body.set_interactable_front_door(null)

func _on_back_body_entered(body: Node2D) -> void:
	if body is Player and body.is_multiplayer_authority():
		print("Joueur %s entré dans l'arrière d'une porte" % [body.name])
		body.set_interactable_back_door(self)

func _on_back_body_exited(body: Node2D) -> void:
	if body is Player and body.is_multiplayer_authority():
		print("Joueur %s sortit de l'arrière d'une porte" % [body.name])
		body.set_interactable_back_door(null)
