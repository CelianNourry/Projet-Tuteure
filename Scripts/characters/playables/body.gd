class_name Body
extends CharacterBody2D

#region Noeuds
@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var inventoryControl: Control= $InventoryUI/Inventory
@onready var inventoryUI: CanvasLayer = $InventoryUI
@onready var interactUI: CanvasLayer = $InteractUI
@onready var interactUILabel: Label = $InteractUI/ColorRect/Label
@onready var staminaUI: CanvasLayer = $Stamina_UI
@onready var healthUI: CanvasLayer = $Health_UI
@onready var camera: Camera2D = $PlayerCamera
@onready var bleeding: GPUParticles2D = $bleeding
#endregion

#region Informations

	#region Inventory
var inventory: Array[Variant] = []
	#endregion

	#region Movement
var isMoving: bool = false
var isSprinting: bool = false
var currentSpeed: float = 50.00

@export var walkSpeed: float = 50.00
@export var sprintSpeed: float = 100.00
@export var tiredSpeed: float = 30.00
	#endregion

	#region Player Stats
@export var stamina: float = 100.00
@export var walkStaminaLoss: float = 1.00
@export var sprintStaminaLoss: float = 5.00
@export var idleStaminaGain: float = 2.00

@export var health: float = 50.00
@export var injuredHealthLoss: float = 0.200
@export var uninjuredHealthGain: float = 0.100

@export var isBleeding: bool = false
	#endregion

	#region Vision Parameters
@export var FOV: float = deg_to_rad(180.00) # Champ de vision
@export var angleBetweenRays: float = deg_to_rad(2.50) # Angle entre chaque raycast
@export var maxViewDistance: float = 400.00 # Distance de vue maximale
	#endregion

	#region Position
@export var spawnCoordinates: Vector2 = Vector2(1820.00, 295.00)
var previousPosition: Vector2
	#endregion

	#region Enemy
var enemyInRange: bool = false
	#endregion

#endregion

#region Interactables
var item: Item
var frontDoor: Door
var backDoor: Door
var highVoltageStation: HVS
#endregion

signal inventory_updated

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	self.global_position = spawnCoordinates
	add_to_group("bodies") # Ajout du noeud dans le groupe de joueurs
	previousPosition = self.global_position
	inventory.resize(12)
	
	if not is_multiplayer_authority(): return
	
	Global.generate_raycasts(self, FOV, angleBetweenRays, maxViewDistance, true)
	camera.enabled = true
	staminaUI.visible = true
	healthUI.visible = true
	inventoryControl.set_player(self)

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
	
	set_velocity(inputVector * currentSpeed)
	move_and_slide()
	
	# Tous les ennemis sont rendus invisibles
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemyInRange:
			enemy.isRevealed = false
	
	# Mais tant que le joueur voit un ennemi, il le révèle
	for ray in get_children():
		if ray is RayCast2D and ray.is_colliding() and ray.get_collider() is Enemy:
			ray.get_collider().isRevealed = true

	# Sprint
	if Input.is_action_just_pressed("ui_shift") and stamina > 0:
		currentSpeed = sprintSpeed
		isSprinting = true
	elif Input.is_action_just_released("ui_shift") or stamina <= 15:
		currentSpeed = walkSpeed
		isSprinting = false
	
	# Tracking de si le joueur a bougé de 0.0100 ou pas
	isMoving = global_position.distance_to(previousPosition) > 0.0100
	var dir: String = Global.vector_to_compass_dir(inputVector)
	# Si le joueur bouge, son animation se met à jour
	if isMoving:
		if dir != "None":
			anim = "run_" + dir
		
		stamina -= (walkStaminaLoss * delta)
		if isSprinting:
			stamina -= (sprintStaminaLoss * delta)
		if stamina <= 0:
			stamina = 0
			currentSpeed = tiredSpeed
			isSprinting = false
				
	# Si le joueur ne bouge pas, sa stamina augmente de idleStaminaGain
	else:
		stamina += (idleStaminaGain * delta) if stamina < 100.00 else 0.00
		if dir != "None":
			anim = "idle_" + dir
			
	if not isBleeding:
		if health < 100.00:
			health += (uninjuredHealthGain * delta)
	else:
		if health > 0.00:
			health -= (injuredHealthLoss * delta)
		
	if isBleeding and not bleeding.emitting:
		bleeding.emitting = true

	update_animated_sprite(anim)
	previousPosition = self.global_position

	for node: Node in get_children():
		if node is Sprite2D or node is Area2D or node is RayCast2D:
			node.rotation = lerp_angle(node.rotation,  inputVector.angle() + PI / 2, delta * 2.0)

func update_animated_sprite(anim: String) -> void:
	animatedSprite.animation = anim
	animatedSprite.play(anim)

func set_interactable_item(i: Item) -> void:
	item = i
	interactUI.visible = i != null
	if i != null:
		interactUILabel.text = Global.E_pickUp

func set_interactable_front_door(d: Door) -> void:
	frontDoor = d
	interactUI.visible = d != null
	if d != null:
		if d.electric and d.electricity:
			interactUILabel.text = Global.W_electric
			return
			
		elif d.isOpened:
			interactUILabel.text = Global.E_close
		else:
			interactUILabel.text = Global.E_open
			
	
func set_interactable_back_door(d: Door) -> void:
	backDoor = d
	interactUI.visible = d != null
	if d != null:
		if d.electric and d.electricity:
			interactUILabel.text = Global.W_electric
			return
		elif d.isLocked:
			interactUILabel.text = Global.L_unlock
		else:
			if d.isOpened:
				interactUILabel.text = Global.E_close
			else:
				interactUILabel.text = Global.E_open
	
func set_interactable_HVS(hvs: HVS) -> void:
	highVoltageStation = hvs
	interactUI.visible = hvs != null
	if hvs != null:
		if hvs._power:
			interactUILabel.text = Global.E_turnOff
		else:
			interactUILabel.text = Global.E_turnOn
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("zoom out") and not camera.zoom <= Vector2(2.0, 2.0):
		camera.zoom -= Vector2(0.3, 0.3)
	if event.is_action_pressed("zoom in") and not camera.zoom >= Vector2(10.0, 10.0):
		camera.zoom += Vector2(0.3, 0.3)
	
	if event.is_action_pressed("ui_inventory"):
		print("Le joueur %s a %s l'inventaire" % [self.name, "fermé" if inventoryUI.visible else "ouvert"])
		inventoryUI.visible = !inventoryUI.visible
	elif event.is_action_pressed("ui_add") and item:
		print("Le joueur %s a ramassé un %s" % [self.name, item.name])
		item.pickup_item(self)
	elif frontDoor:
		if event.is_action_pressed("interact"):
			frontDoor.rpc("interact_with_front_door")
			set_interactable_front_door(frontDoor)
	elif backDoor:
		if event.is_action_pressed("interact"):
			backDoor.rpc("interact_with_back_door", "interact")
			set_interactable_back_door(backDoor)
		elif event.is_action_pressed("lock"):
			backDoor.rpc("interact_with_back_door", "lock")
			set_interactable_back_door(backDoor)
	elif highVoltageStation and event.is_action_pressed("interact"):
			highVoltageStation.rpc("switch_power_state")
			set_interactable_HVS(highVoltageStation)

# Ajout d'un item dans l'inventaire
func add_item(it: Dictionary) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["name"] == it["name"]:
			inventory[i]["quantity"] += it["quantity"]
			inventory_updated.emit()
			return true
		elif inventory[i] == null:
			inventory[i] = it
			inventory_updated.emit()
			return true
	return false

# Suppression d'un item dans l'inventaire
func remove_item(itemName: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["name"] == itemName:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false

# On rend les ennemis visibles s'ils sont très proche du joueur
func _on_enemy_detection_range_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.isRevealed = true
		enemyInRange = true

func _on_enemy_detection_range_body_exited(body: Node2D) -> void:
	if body is Enemy:
		body.isRevealed = false
		enemyInRange = false

func start_bleeding() -> void:
	if not isBleeding or not bleeding.emitting:
		bleeding.emitting = true
		isBleeding = true
		idleStaminaGain = 1.00
		
func stop_bleeding() -> void:
	if isBleeding or bleeding.emitting:
		bleeding.emitting = false
		isBleeding = false
		idleStaminaGain = 2.00
	
func take_damage(damage: float, activatesBleeding: bool) -> void:
	if (health - damage) > 0.00:
		health -= damage
	else:
		health = 0.00
	
	if activatesBleeding: start_bleeding()
	
