@tool
class_name Door
extends StaticBody2D

#region Nodes
@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
#endregion

#region Informations
@export var isLocked: bool
@export var isOpened: bool
@export var seenByBody: bool
#endregion

#region Sprites
const opened: Resource = preload("res://Sprites/interactables/iron bars door - OPENED.png")
const closed: Resource = preload("res://Sprites/interactables/iron bars door - CLOSED.png")
#endregion


func _ready() -> void:
	add_to_group("doors")
	if isOpened and isLocked:
		push_error("%s cannot be opened and locked at the same time. Fix it in the editor" % [self.name])
		return

	# On active ou non la collision de la porte selon si elle est ouverte ou pas
	collisionShape.disabled = isOpened
	update_sprite()
	
# Pour voir si la porte est ouverte ou non dans l'editeur
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_sprite()
		
func update_sprite() -> void:
	sprite.texture = opened if isOpened else closed
	
func switch_collision() -> void:
	collisionShape.disabled = !collisionShape.disabled

@rpc("any_peer", "call_local")
func interact_with_front_door() -> bool:
	if isLocked:
		print("La porte est verrouilée !")
		return false
		
	isOpened = !isOpened
	switch_collision()
	update_sprite()
	return true
		
@rpc("any_peer", "call_local")
func interact_with_back_door(action: String) -> bool:
	match action:
		"interact":
			return interact_with_front_door()
		"lock":
			if !isOpened:
				isLocked = !isLocked
				print("Porte %s" % ("verrouillée" if isLocked else "déverrouillée"))
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
