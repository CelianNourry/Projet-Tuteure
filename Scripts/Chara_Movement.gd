class_name Player
extends CharacterBody2D

# Noeuds du joueur
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	animatedSprite = $AnimatedSprite2D,
	inventoryControl = $InventoryUI/Inventory,
	inventoryUI = $InventoryUI,
	interactUI = $InteractUI,
	staminaBar = $Stamina_bar,
	camera = $PlayerCamera,
	bleeding = $bleeding
}

# Informations actuelles du joueur
@export var INFO: Dictionary[StringName, Variant] = {
	# Inventaire
	inventory = [],
	
	# Statuts
	isHosting = null,
	isMoving = false,
	isSprinting = false,
	isBleeding = false,
	
	# Détection d'objet avec interaction
	interactableIttem = null,
	interactableFrontDoor = null,
	interactableBackDoor = null,
	
	# Statistiques
	currentSpeed = 125.00,
	stamina = 100.00,
	walkSpeed = 125.00,
	sprintSpeed= 250.00,
	tiredSpeed = 50.00,
	walkStaminaLoss = 1.00,
	sprintStaminaLoss = 5.00,
	idleStaminaGain = 2.00,
	
	# Position à la frame précédente
	previousPosition = null
}

signal inventory_updated

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	INFO.isHosting = true if multiplayer.get_unique_id() == 1 else false # Le premier joueur est l'hote
	add_to_group("players") # Ajout du noeud dans le groupe de joueurs
	NODES.collisionShape.disabled = !INFO.isHosting # On désactive les collisions pour l'esprit
	INFO.previousPosition = self.global_position
	INFO.inventory.resize(12)
	
	NODES.camera.enabled = true
	NODES.staminaBar.visible = true
	NODES.animatedSprite.visible = INFO.isHosting
	NODES.inventoryControl.set_player(self)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	velocity = Vector2.ZERO
	var anim: String = "idle"

	# Sprint
	if Input.is_action_just_pressed("ui_shift") and INFO.stamina > 0:
		INFO.currentSpeed = INFO.sprintSpeed
		INFO.isSprinting = true
	elif Input.is_action_just_released("ui_shift") or INFO.stamina <= 15:
		INFO.currentSpeed = INFO.walkSpeed
		INFO.isSprinting = false

	# Mouvement du joueur sous forme de vecteur
	var inputVector: Vector2 = Vector2(
		float(Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right")) -
		float(Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left")),
		float(Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down")) -
		float(Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"))
	)
	
	# Tracking de si le joueur a bougé de 0.0100 ou pas
	INFO.isMoving = global_position.distance_to(INFO.previousPosition) > 0.0100

	# Si le joueur bouge, son animation se met à jour
	if INFO.isMoving:
		match inputVector:
			Vector2.UP:
				anim = "walkup"
			Vector2.DOWN:
				anim = "walkdown"
			Vector2.RIGHT:
				anim = "walkright"
			Vector2.LEFT:
				anim = "walkleft"
			_:
				anim = "idle"
				
	# Si le joueur ne bouge pas, sa stamina augmente de idleStaminaGain
	else: INFO.stamina += (INFO.idleStaminaGain * delta) if INFO.stamina < 100.00 else 0.00
			
	if global_position.distance_to(INFO.previousPosition) > 0.0100:
		INFO.stamina -= (INFO.walkStaminaLoss * delta)
		if INFO.isSprinting:
			INFO.stamina -= (INFO.sprintStaminaLoss * delta)
		if INFO.stamina <= 0:
			INFO.stamina = 0
			INFO.currentSpeed = INFO.tiredSpeed
			INFO.isSprinting = false

	update_anuimated_sprite(anim)
	INFO.previousPosition = self.global_position

	velocity = inputVector.normalized() * INFO.currentSpeed
	set_velocity(velocity)
	move_and_slide()


func update_anuimated_sprite(anim: String) -> void:
	NODES.animatedSprite.animation = anim

func set_interactable_item(item: Node2D) -> void:
	INFO.interactableIttem = item
	NODES.interactUI.visible = item != null

func set_interactable_front_door(door: Door) -> void:
	INFO.interactableFrontDoor = door
	NODES.interactUI.visible = door != null
	
func set_interactable_back_door(door: Door) -> void:
	INFO.interactableBackDoor = door
	NODES.interactUI.visible = door != null
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("ui_inventory") and INFO.isHosting:
		print("Le joueur ", self, " a interagit avec l'inventaire")
		NODES.inventoryUI.visible = !NODES.inventoryUI.visible
	elif event.is_action_pressed("ui_add") and INFO.interactableIttem and INFO.isHosting:
		print("Prise de l'item : ", INFO.interactableIttem.name)
		INFO.interactableIttem.pickup_item(self)
	elif INFO.interactableFrontDoor:
		if event.is_action_pressed("interact"):
			INFO.interactableFrontDoor.interact_with_front_door()
	elif INFO.interactableBackDoor:
		if event.is_action_pressed("interact"):
			INFO.interactableBackDoor.interact_with_back_door("interact")
		elif event.is_action_pressed("lock"):
			INFO.interactableBackDoor.interact_with_back_door("lock")
			
func apply_item_effect(item: Dictionary) -> void:
	if not is_multiplayer_authority(): return
	
	match item["effect"]:
		"Vitesse":
			INFO.currentSpeed += 200.00
			print("Vitesse augmentée de ", INFO.currentSpeed)
		"+100 HP":
			print("Blessures soignées.")
			INFO.isBleeding = false
		_ :
			print("Aucun effet pour cet objet.")

# Ajout d'un item dans l'inventaire
func add_item(item: Dictionary) -> bool:
	for i in range(INFO.inventory.size()):
		if INFO.inventory[i] != null and INFO.inventory[i]["name"] == item["name"] and INFO.inventory[i]["effect"] == item["effect"]:
			INFO.inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			return true
		elif INFO.inventory[i] == null:
			INFO.inventory[i] = item
			inventory_updated.emit()
			return true
	return false

# Suppression d'un item dans l'inventaire
func remove_item(item_name: String, item_effect: String) -> bool:
	for i in range(INFO.inventory.size()):
		if INFO.inventory[i] != null and INFO.inventory[i]["name"] == item_name and INFO.inventory[i]["effect"] == item_effect:
			INFO.inventory[i]["quantity"] -= 1
			if INFO.inventory[i]["quantity"] <= 0:
				INFO.inventory[i] = null
			inventory_updated.emit()
			return true
	return false

func get_host_coordinates() -> Vector2:
	for node in get_tree().get_nodes_in_group("players"):
		if node.INFO.isHosting:
			return node.global_position
	return Vector2.ZERO
