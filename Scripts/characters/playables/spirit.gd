class_name Spirit
extends CharacterBody2D

# Noeuds du joueur
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	animatedSprite = $AnimatedSprite2D,
	camera = $Camera2D,
	interactUI = $InteractUI
}

# Informations actuelles du joueur. Elles ne sont pas synchronisées entre les joueurs dans le MultiplayerSynchronizer
@export var INFO: Dictionary[StringName, Variant] = {
	# Statuts
	isMoving = false,
	
	# Statistiques
	currentSpeed = 100.00,
	walkSpeed = 100.00,
	maxSpiritRange = 150.00, # Rayon maximum auquel le pair peut se déplacer autour de l'hote
	
	spawnCoordinates = Vector2(435.00, 170.00)
}

# Objets dont le joueur peut intéragir avec. Ils ne sont pas synchronisés entre les joueurs dans le MultiplayerSynchronizer
@export var INTERACTABLES: Dictionary[StringName, Node] = {
	item = null,
	frontDoor = null,
	backDoor = null,
}

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	self.global_position = INFO.spawnCoordinates
	add_to_group("spirits") # Ajout du noeud dans le groupe d'esprits
	
	if not is_multiplayer_authority(): return
	NODES.collisionShape.disabled = false
	
	# Le sprite de l'esprit est invisible pour tout le monde de base, mais il devient visible seulement pour le joueur qui le controle
	NODES.animatedSprite.visible = true
	NODES.camera.enabled = true

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	velocity = Vector2.ZERO
	var anim: String = "idle"

	# Mouvement du l'esprit sous forme de vecteur
	var inputVector: Vector2 = Vector2(
		float(Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right")) -
		float(Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left")),
		float(Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down")) -
		float(Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"))
	)
	
	# Si le joueur bouge, son animation se met à jour
	if INFO.isMoving:
		match inputVector:
			Vector2.UP:
				anim = "idle"
			Vector2.DOWN:
				anim = "idle"
			Vector2.RIGHT:
				anim = "idle"
			Vector2.LEFT:
				anim = "idle"
			_:
				anim = "idle"

	update_animated_sprite(anim)

	# L'esprit doit rester dans un rayon atour du corps
	velocity = Global.enforce_distance_from_host(inputVector, self.global_position, INFO.maxSpiritRange, delta)
	set_velocity(velocity)
	move_and_slide()

func update_animated_sprite(anim: String) -> void:
	NODES.animatedSprite.animation = anim

func set_interactable_item(item: Node2D) -> void:
	INTERACTABLES.item = item
	NODES.interactUI.visible = item != null

func set_interactable_front_door(door: Door) -> void:
	INTERACTABLES.frontDoor = door
	NODES.interactUI.visible = door != null
	
func set_interactable_back_door(door: Door) -> void:
	INTERACTABLES.backDoor = door
	NODES.interactUI.visible = door != null
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if INTERACTABLES.frontDoor:
		if event.is_action_pressed("interact"):
			INTERACTABLES.frontDoor.rpc("interact_with_front_door")
	elif INTERACTABLES.backDoor:
		if event.is_action_pressed("interact"):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "interact")
		elif event.is_action_pressed("lock"):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "lock")
			
func apply_item_effect(item: Dictionary) -> void:
	if not is_multiplayer_authority(): return
	
	match item["effect"]:
		"Vitesse":
			INFO.currentSpeed += 50.00
			print("Vitesse augmentée de ", INFO.currentSpeed)
		_ :
			print("Aucun effet pour cet objet.")
