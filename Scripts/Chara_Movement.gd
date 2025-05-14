extends CharacterBody2D

@onready var inventoryControl = $InventoryUI/Inventory
@onready var inventoryUI = $InventoryUI

@onready var interact_ui = $InteractUI
@onready var camera = $PlayerCamera

@export var SPEED: int = 125
@export var WALK_SPEED: int = 125
@export var SPRINT_SPEED: int = 250
@export var TIRED_SPEED: int = 50
@export var STAMINA: float = 100.00

var WALK_LOSS: float = 0.025
var SPRINT_LOSS: float = 0.20
var IDLE_STAM_GAIN: float = 0.10

var isSprinting: bool = false
var isMoving: bool = false

# Inventaire propre au joueur
var inventory = []
signal inventory_updated

var interactable_item: Node2D

# Determine le type de joueur. L'hote est le joueur, le pair est l'esprit
var HOST: int

func _enter_tree() -> void:
	HOST = 1 if multiplayer.get_unique_id() == 1 else 0
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	print(HOST)
	$CollisionShape2D.disabled = !HOST # On désactive les collisions pour l'esprit
	inventory.resize(12)
	if is_multiplayer_authority():
		camera.enabled = true
		inventoryControl.set_player(self)
	else:
		camera.enabled = false
	# Rendre l'hote visible tandis que l'esprit ne l'est pas (provisoire)
	$AnimatedSprite2D.visible = HOST

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		$AnimatedSprite2D.animation = "idle"
			
		velocity = Vector2()

		if Input.is_action_just_pressed("ui_shift") and STAMINA > 0:
			SPEED = SPRINT_SPEED
			isSprinting = true
		if Input.is_action_just_released("ui_shift") or STAMINA <= 0:
			SPEED = WALK_SPEED
			isSprinting = false

		if Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"):
			velocity.y -= 1
			$AnimatedSprite2D.animation = "walkup"
			isMoving = true
		elif Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down"):
			velocity.y += 1
			$AnimatedSprite2D.animation = "walkdown"
			isMoving = true
		elif Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right"):
			velocity.x += 1
			$AnimatedSprite2D.animation = "walkright"
			isMoving = true
		elif Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left"):
			velocity.x -= 1
			$AnimatedSprite2D.animation = "walkleft"
			isMoving = true
		else:
			$AnimatedSprite2D.animation = "idle"
			isMoving = false
			if STAMINA <= 100:
				STAMINA += IDLE_STAM_GAIN

		if isMoving:
			STAMINA -= WALK_LOSS
			if isSprinting:
				STAMINA -= SPRINT_LOSS
			if STAMINA <= 0:
				STAMINA += WALK_LOSS
				SPEED = TIRED_SPEED

		velocity = velocity.normalized() * SPEED
		set_velocity(velocity)
		move_and_slide()

func set_interactable_item(item: Node2D) -> void:
	interactable_item = item
	interact_ui.visible = item != null
		
func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("ui_inventory") and HOST:
			print("Le joueur ", self, " a interagit avec l'inventaire")
			inventoryUI.visible = !inventoryUI.visible
		elif event.is_action_pressed("ui_add") and interactable_item and HOST:
			print("Demande de ramassage envoyée au serveur pour : ", interactable_item.name)
			interactable_item.pickup_item(self)

func apply_item_effect(item: Dictionary) -> void:
	if !is_multiplayer_authority():
		return
	match item["effect"]:
		"Vitesse":
			SPEED += 200
			print("Vitesse augmentée de ", SPEED)
		_ :
			print("Aucun effet pour cet objet.")

# Ajout d'un item dans l'inventaire
func add_item(item: Dictionary) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["name"] == item["name"] and inventory[i]["effect"] == item["effect"]:
			inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			return true
		elif inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			return true
	return false

# Suppression d'un item dans l'inventaire
func remove_item(item_name: String, item_effect: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["name"] == item_name and inventory[i]["effect"] == item_effect:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true
	return false
