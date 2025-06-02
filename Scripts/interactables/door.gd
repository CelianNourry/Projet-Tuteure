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
@export var electric: bool
var electricity: bool
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
	if electric:
		electricity = Global.get_game_node().power
	update_sprite()
	
# Pour voir si la porte est ouverte ou non dans l'editeur
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_sprite()
		
func switch_electric_state() -> void:
	if electric:
		electricity = !electricity
	
func update_sprite() -> void:
	sprite.texture = opened if isOpened else closed
	
func switch_collision() -> void:
	collisionShape.disabled = !collisionShape.disabled

@rpc("any_peer", "call_local")
func interact_with_front_door() -> void:
	if electric and electricity:
		print("lol")
		return
	if isLocked:
		print("La porte est verrouilée !")
		return
		
	isOpened = !isOpened
	switch_collision()
	update_sprite()
		
@rpc("any_peer", "call_local")
func interact_with_back_door(action: String) -> void:
	if electric and electricity: return
	match action:
		"interact":
			return interact_with_front_door()
		"lock":
			if !isOpened:
				isLocked = !isLocked
				print("Porte %s" % ("verrouillée" if isLocked else "déverrouillée"))
		_:
			return

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
