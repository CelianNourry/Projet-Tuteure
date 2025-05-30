@tool
class_name Door
extends StaticBody2D

# Noeuds de la porte
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	sprite = $Sprite2D
}

# Informations de la porte
@export var INFO: Dictionary[StringName, Variant] = {
	locked = false,
	opened = true,
	seenByBody = false,
}

const SPRITES: Dictionary[StringName, Resource] = {
	opened = preload("res://Sprites/interactables/iron bars door - OPENED.png"),
	closed = preload("res://Sprites/interactables/iron bars door - CLOSED.png")
}

func _ready() -> void:
	if not Engine.is_editor_hint():
		update_sprite()
	if INFO.opened:
		if !INFO.locked: # La porte est censée etre fermée de base, donc on retire sa collision si elle est ouverte depuis l'inspecteur
			switch_collision()
			update_sprite()
		else:
			push_error("%s cannot be opened and locked at the same time. Fix it in the editor" % [self])

# Pour voir si la porte est ouverte ou non dans l'editeur
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_sprite()
		
func update_sprite() -> void:
	NODES.sprite.texture = SPRITES.opened if INFO.opened else SPRITES.closed
	
func switch_collision() -> void:
	NODES.collisionShape.disabled = !NODES.collisionShape.disabled

@rpc("any_peer", "call_local")
func interact_with_front_door() -> bool:
	if INFO.locked:
		print("La porte est verrouilée !")
		return false
		
	INFO.opened = !INFO.opened
	switch_collision()
	update_sprite()
	return true
		
@rpc("any_peer", "call_local")
func interact_with_back_door(action: String) -> bool:
	match action:
		"interact":
			return interact_with_front_door()
		"lock":
			if !INFO.opened:
				INFO.locked = !INFO.locked
				print("Porte %s" % ("verrouillée" if INFO.locked else "déverrouillée"))
				return true
			return false
		_:
			return false

func _on_front_body_entered(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		body.set_interactable_front_door(self)

func _on_front_body_exited(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		body.set_interactable_front_door(null)

func _on_back_body_entered(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		body.set_interactable_back_door(self)

func _on_back_body_exited(body: Node2D) -> void:
	if not body.is_multiplayer_authority(): return
	
	if (body is Body) or (body is Spirit):
		body.set_interactable_back_door(null)
