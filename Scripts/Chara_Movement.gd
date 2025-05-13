extends CharacterBody2D

@onready var inventoryControl = $InventoryUI/Inventory
@onready var inventoryUI = $InventoryUI

@onready var interact_ui = $InteractUI
@onready var camera = $PlayerCamera

@export var SPEED = 125
@export var WALK_SPEED = 125
@export var SPRINT_SPEED = 250
@export var TIRED_SPEED = 50
@export var STAMINA = 100

var WALK_LOSS = 0.025
var SPRINT_LOSS = 0.2
var IDLE_STAM_GAIN = 0.1

var isSprinting = false
var isMoving = false

# Inventaire propre au joueur
var inventory = []
signal inventory_updated

var interactable_item = null

var anim = null

# Determine le type de joueur. L'hote est le joueur, le pair est l'esprit
var HOST: int

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	HOST = 1 if multiplayer.get_unique_id() == 1 else 0
	inventory.resize(6)
	if is_multiplayer_authority():
		camera.enabled = true
		inventoryControl.set_player(self)
	else:
		camera.enabled = false
		
func set_animation(anim_name: String) -> void:
	$AnimatedSprite2D.animation = anim_name
	$AnimatedSprite2D.visible = HOST

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		anim = "idle"
			
		velocity = Vector2()

		if Input.is_action_just_pressed("ui_shift") and STAMINA > 0:
			SPEED = SPRINT_SPEED
			isSprinting = true
		if Input.is_action_just_released("ui_shift") or STAMINA <= 0:
			SPEED = WALK_SPEED
			isSprinting = false

		if Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"):
			velocity.y -= 1
			anim = "walkup"
			isMoving = true
		elif Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down"):
			velocity.y += 1
			anim = "walkdown"
			isMoving = true
		elif Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right"):
			velocity.x += 1
			anim = "walkright"
			isMoving = true
		elif Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left"):
			velocity.x -= 1
			anim = "walkleft"
			isMoving = true
		else:
			anim = "idle"
			isMoving = false
			if STAMINA <= 100:
				STAMINA += IDLE_STAM_GAIN
				
		# Mettre à jour l'animation pour tous les joueurs
		set_animation(anim)

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

func set_interactable_item(item) -> void:
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

func apply_item_effect(item):
	if !is_multiplayer_authority():
		return
	match item["effect"]:
		"Vitesse":
			SPEED += 200
			print("Vitesse augmentée de ", SPEED)
		_ :
			print("Aucun effet pour cet objet.")

# Ajout d'un item dans l'inventaire
func add_item(item) -> bool:
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
