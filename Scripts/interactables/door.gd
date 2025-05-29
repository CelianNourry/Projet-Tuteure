class_name Door
extends StaticBody2D

# Noeuds de la porte
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	sprite = $Sprite2D
}

# Informations de la porte
@export var INFO: Dictionary[StringName, Variant] = {
	locked = true,
	opened = false,
	seenByBody = false,
}

const SPRITES: Dictionary[StringName, Resource] = {
	opened = preload("res://Sprites/interactables/iron bars door - OPENED.png"),
	closed = preload("res://Sprites/interactables/iron bars door - CLOSED.png")
}

func ready() -> void:
	update_sprite()

func update_sprite() -> void:
	NODES.sprite.texture = SPRITES.opened if INFO.opened else SPRITES.closed

@rpc("any_peer", "call_local")
func interact_with_front_door() -> void:
	if INFO.locked:
		print("La porte est verrouilée !")
	else:
		INFO.opened = !INFO.opened
		NODES.collisionShape.disabled = !NODES.collisionShape.disabled
		update_sprite()
		
@rpc("any_peer", "call_local")
func interact_with_back_door(action: String) -> void:
	match action:
		"interact":
			interact_with_front_door()
		"lock":
			INFO.locked = !INFO.locked
			print("Porte %s" % ("verrouillée" if INFO.locked else "déverrouillée"))

func _on_front_body_entered(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		print("Joueur %s entré dans la face d'une porte" % [body.name])
		body.set_interactable_front_door(self)

func _on_front_body_exited(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		print("Joueur %s sortit de la face d'une porte" % [body.name])
		body.set_interactable_front_door(null)

func _on_back_body_entered(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		print("Joueur %s entré dans l'arrière d'une porte" % [body.name])
		body.set_interactable_back_door(self)

func _on_back_body_exited(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		print("Joueur %s sortit de l'arrière d'une porte" % [body.name])
		body.set_interactable_back_door(null)
