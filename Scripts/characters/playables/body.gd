class_name Body
extends CharacterBody2D

# Noeuds du joueur
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	animatedSprite = $AnimatedSprite2D,
	inventoryControl = $InventoryUI/Inventory,
	inventoryUI = $InventoryUI,
	interactUI = $InteractUI,
	interactUILabel = $InteractUI/ColorRect/Label,
	staminaUI = $Stamina_UI,
	healthUI = $Health_UI,
	camera = $PlayerCamera,
	bleeding = $bleeding
}

# Informations actuelles du joueur. Elles ne sont pas synchronisées entre les joueurs dans le MultiplayerSynchronizer
@export var INFO: Dictionary[StringName, Variant] = {
	inventory = [],
	
	# Statuts
	isMoving = false,
	isSprinting = false,
	isBleeding = false,
	
	# Statistiques
	currentSpeed = 50.00,
	walkSpeed = 50.00,
	sprintSpeed= 100.00,
	tiredSpeed = 30.00,
	stamina = 100.00,
	walkStaminaLoss = 1.00,
	sprintStaminaLoss = 5.00,
	idleStaminaGain = 2.00,
	health = 50.00,
	injuredHealthLoss = 0.2,
	uninjuredHealthGain = 0.1,
	
	FOV = deg_to_rad(180.00), # Champ de vision
	angleBetweenRays = deg_to_rad(1.00), # Angle entre chaque raycast
	maxViewDistance = 800.00, # Distance maximale à laquelle le joueur peut voir les ennemis
	enemyInRange = false,
	
	spawnCoordinates = Vector2(435.00, 170.00),
	
	previousPosition = null # Position à la frame précédente
}

# Objets dont le joueur peut intéragir avec. Ils ne sont pas synchronisés entre les joueurs dans le MultiplayerSynchronizer
@export var INTERACTABLES: Dictionary[StringName, Node] = {
	item = null,
	frontDoor = null,
	backDoor = null,
	highVoltageStation = null
}

signal inventory_updated

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	self.global_position = INFO.spawnCoordinates
	add_to_group("bodies") # Ajout du noeud dans le groupe de joueurs
	INFO.previousPosition = self.global_position
	INFO.inventory.resize(12)
	
	if not is_multiplayer_authority(): return
	
	Global.generate_raycasts(self, INFO.FOV, INFO.angleBetweenRays, INFO.maxViewDistance, true)
	NODES.camera.enabled = true
	NODES.staminaUI.visible = true
	NODES.healthUI.visible = true
	NODES.inventoryControl.set_player(self)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	var anim: String = "idle_S"
	
	var inputVector: Vector2 = Vector2(
		float(Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right")) -
		float(Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left")),
		float(Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down")) -
		float(Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"))
	).normalized()
	inputVector = Global.cartesian_to_isometric(inputVector)
	
	set_velocity(inputVector * INFO.currentSpeed)
	move_and_slide()
	
	# Tous les ennemis sont rendus invisibles
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not INFO.enemyInRange:
			enemy.INFO.isRevealed = false
	
	# Mais tant que le joueur voit un ennemi, il le révèle
	for ray in get_children():
		if ray is RayCast2D and ray.is_colliding() and ray.get_collider() is Enemy:
			ray.get_collider().INFO.isRevealed = true

	# Sprint
	if Input.is_action_just_pressed("ui_shift") and INFO.stamina > 0:
		INFO.currentSpeed = INFO.sprintSpeed
		INFO.isSprinting = true
	elif Input.is_action_just_released("ui_shift") or INFO.stamina <= 15:
		INFO.currentSpeed = INFO.walkSpeed
		INFO.isSprinting = false

	
	# Tracking de si le joueur a bougé de 0.0100 ou pas
	INFO.isMoving = global_position.distance_to(INFO.previousPosition) > 0.0100

	var dir: String = Global.vector_to_compass_dir(inputVector)
	# Si le joueur bouge, son animation se met à jour
	if INFO.isMoving:
		if dir != "None":
			anim = "run_" + dir
				
	# Si le joueur ne bouge pas, sa stamina augmente de idleStaminaGain
	else:
		INFO.stamina += (INFO.idleStaminaGain * delta) if INFO.stamina < 100.00 else 0.00
		if dir != "None":
			anim = "idle_" + dir
			
	if global_position.distance_to(INFO.previousPosition) > 0.0100:
		INFO.stamina -= (INFO.walkStaminaLoss * delta)
		if INFO.isSprinting:
			INFO.stamina -= (INFO.sprintStaminaLoss * delta)
		if INFO.stamina <= 0:
			INFO.stamina = 0
			INFO.currentSpeed = INFO.tiredSpeed
			INFO.isSprinting = false
			
	if not INFO.isBleeding:
		if INFO.health < 100.00:
			INFO.health += (INFO.uninjuredHealthGain * delta)
	else:
		if INFO.health > 0.00:
			INFO.health -= (INFO.injuredHealthLoss * delta)

	update_animated_sprite(anim)
	INFO.previousPosition = self.global_position

	for node: Node in get_children():
		if node is Sprite2D or node is Area2D or node is RayCast2D:
			node.rotation = lerp_angle(node.rotation,  inputVector.angle() + PI / 2, delta * 2.0)

func update_animated_sprite(anim: String) -> void:
	NODES.animatedSprite.animation = anim
	NODES.animatedSprite.play(anim)

func set_interactable_item(item: Item) -> void:
	INTERACTABLES.item = item
	NODES.interactUI.visible = item != null
	if item != null:
		NODES.interactUILabel.text = Global.TEXT.E_open

func set_interactable_front_door(door: Door) -> void:
	INTERACTABLES.frontDoor = door
	NODES.interactUI.visible = door != null
	if door != null:
		if door.INFO.opened:
			NODES.interactUILabel.text = Global.TEXT.E_close
		else:
			NODES.interactUILabel.text = Global.TEXT.E_open
	
func set_interactable_back_door(door: Door) -> void:
	INTERACTABLES.backDoor = door
	NODES.interactUI.visible = door != null
	if door != null:
		if door.INFO.locked:
			NODES.interactUILabel.text = Global.TEXT.L_unlock
		else:
			if door.INFO.opened:
				NODES.interactUILabel.text = Global.TEXT.E_close
			else:
				NODES.interactUILabel.text = Global.TEXT.E_open
	
func set_interactable_HVS(highVoltageStation: HVS) -> void:
	INTERACTABLES.highVoltageStation = highVoltageStation
	NODES.interactUI.visible = highVoltageStation != null
	if highVoltageStation != null:
		if highVoltageStation._power:
			NODES.interactUILabel.text = Global.TEXT.E_turnOff
		else:
			NODES.interactUILabel.text = Global.TEXT.E_turnOn
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("zoom out") and not NODES.camera.zoom <= Vector2(2.0, 2.0):
		NODES.camera.zoom -= Vector2(0.3, 0.3)
	if event.is_action_pressed("zoom in") and not NODES.camera.zoom >= Vector2(10.0, 10.0):
		NODES.camera.zoom += Vector2(0.3, 0.3)
	
	if event.is_action_pressed("ui_inventory"):
		print("Le joueur %s a %s l'inventaire" % [self.name, "fermé" if NODES.inventoryUI.visible else "ouvert"])
		NODES.inventoryUI.visible = !NODES.inventoryUI.visible
	elif event.is_action_pressed("ui_add") and INTERACTABLES.item:
		print("Le joueur %s a ramassé un %s" % [self.name, INTERACTABLES.item.name])
		INTERACTABLES.item.pickup_item(self)
	elif INTERACTABLES.frontDoor:
		if event.is_action_pressed("interact"):
			INTERACTABLES.frontDoor.rpc("interact_with_front_door")
			set_interactable_front_door(INTERACTABLES.frontDoor)
	elif INTERACTABLES.backDoor:
		if event.is_action_pressed("interact"):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "interact")
			set_interactable_back_door(INTERACTABLES.backDoor)
		elif event.is_action_pressed("lock"):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "lock")
			set_interactable_back_door(INTERACTABLES.backDoor)
	elif INTERACTABLES.highVoltageStation and event.is_action_pressed("interact"):
			INTERACTABLES.highVoltageStation.rpc("switch_power_state")
			set_interactable_HVS(INTERACTABLES.highVoltageStation)

# Ajout d'un item dans l'inventaire
func add_item(item: Dictionary) -> bool:
	for i in range(INFO.inventory.size()):
		if INFO.inventory[i] != null and INFO.inventory[i]["name"] == item["name"]:
			INFO.inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			return true
		elif INFO.inventory[i] == null:
			INFO.inventory[i] = item
			inventory_updated.emit()
			return true
	return false

# Suppression d'un item dans l'inventaire
func remove_item(itemName: String) -> bool:
	for i in range(INFO.inventory.size()):
		if INFO.inventory[i] != null and INFO.inventory[i]["name"] == itemName:
			INFO.inventory[i]["quantity"] -= 1
			if INFO.inventory[i]["quantity"] <= 0:
				INFO.inventory[i] = null
			inventory_updated.emit()
			return true
	return false

# On rend les ennemis visibles s'ils sont très proche du joueur
func _on_enemy_detection_range_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.INFO.isRevealed = true
		INFO.enemyInRange = true

func _on_enemy_detection_range_body_exited(body: Node2D) -> void:
	if body is Enemy:
		body.INFO.isRevealed = false
		INFO.enemyInRange = false
		
func stop_bleeding() -> void:
	NODES.bleeding.emitting = false
	INFO.idleStaminaGain = 2.00
