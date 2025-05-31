class_name Spirit
extends CharacterBody2D

#region Nodes
@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var interactUI: CanvasLayer = $InteractUI
@onready var interactUILabel: Label = $InteractUI/ColorRect/Label
@onready var powerUI: CanvasLayer = $PowerUI
#endregion

#region Informations
# Statuts
var isMoving: bool = false

# Statistiques
@export var currentSpeed: float = 100.00
@export var maxSpiritRange: float = 150.00 # Rayon maximum auquel le Spirit peut se déplacer autour du Body
@export var power: float = 100.00 # pouvoir restant, sert à faire des actions

@export var spawnCoordinates: Vector2 = Vector2(435.00, 170.00)
#endregion

#region Interactables
var frontDoor: Door = null
var backDoor: Door = null
var highVoltageStation: HVS = null
#endregion

#region Power Cost
@export var interactWithDoorCost: float = 25.00
@export var lockOrUnlockDoorCost: float = 10.00
@export var interactWithHVSCost: float = 10.00
"""@export var failedActionCost = 2.50 # Inutilisé pour le moment """
#endregion

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	self.global_position = spawnCoordinates
	add_to_group("spirits") # Ajout du noeud dans le groupe d'esprits
	
	if not is_multiplayer_authority(): return
	collisionShape.disabled = false
	powerUI.visible = true
	
	# Le sprite de l'esprit est invisible pour tout le monde de base, mais il devient visible seulement pour le joueur qui le controle
	animatedSprite.visible = true
	camera.enabled = true

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
	if isMoving:
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

	# Le Spirit doit rester dans un rayon atour du Body
	velocity = Global.enforce_distance_from_host(inputVector, currentSpeed, self.global_position, maxSpiritRange, delta)
	velocity = Global.cartesian_to_isometric(velocity)
	set_velocity(velocity)
	move_and_slide()
	
func update_animated_sprite(anim: String) -> void:
	animatedSprite.animation = anim

# Deduit des points de power
func use_power(powerCost: float) -> bool:
	if (power - powerCost) > 0.00:
		power -= powerCost
		return true
	return false

@rpc("any_peer", "call_local")
func add_power(powerGrant: float) -> void:
	if not is_multiplayer_authority(): return
	
	if not (power > (100.00 - powerGrant)):
		power += powerGrant
		return
	power = 100.00
		
func set_interactable_front_door(door: Door) -> void:
	frontDoor = door
	interactUI.visible = door != null
	if door != null:
		if door.isOpened:
			interactUILabel.text = "E - Fermer"
		else:
			interactUILabel.text = "E - Ouvrir"
	
func set_interactable_back_door(door: Door) -> void:
	backDoor = door
	interactUI.visible = door != null
	if door != null:
		if door.isLocked:
			interactUILabel.text = "L - Dérouiller"
		else:
			if door.isOpened:
				interactUILabel.text = "E - Fermer"
			else:
				interactUILabel.text = "E - Ouvrir"
	
func set_interactable_HVS(hvs: HVS) -> void:
	highVoltageStation = hvs
	interactUI.visible = hvs != null
	if hvs != null:
		if hvs._power:
			interactUILabel.text = "E - Eteindre"
		else:
			interactUILabel.text = "E - Allumer"
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("zoom out") and not camera.zoom <= Vector2(2.0, 2.0):
		camera.zoom -= Vector2(0.3, 0.3)
	elif event.is_action_pressed("zoom in") and not camera.zoom >= Vector2(10.0, 10.0):
		camera.zoom += Vector2(0.3, 0.3)
	
	if event.is_action_pressed("interact") and (frontDoor or backDoor):
		if frontDoor and use_power(interactWithDoorCost):
			frontDoor.rpc("interact_with_front_door")
			set_interactable_front_door(frontDoor)
		elif backDoor and use_power(interactWithDoorCost):
			backDoor.rpc("interact_with_back_door", "interact")
			set_interactable_back_door(backDoor)
	elif backDoor and event.is_action_pressed("lock"):
		if use_power(lockOrUnlockDoorCost):
			backDoor.rpc("interact_with_back_door", "lock")
			set_interactable_back_door(backDoor)
		
	elif highVoltageStation and event.is_action_pressed("interact"):
		if use_power(interactWithHVSCost):
			highVoltageStation.rpc("switch_power_state")
			set_interactable_HVS(highVoltageStation)
