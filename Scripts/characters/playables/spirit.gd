class_name Spirit
extends CharacterBody2D

# Noeuds du joueur
@onready var NODES: Dictionary[StringName, Node] = {
	collisionShape = $CollisionShape2D,
	animatedSprite = $AnimatedSprite2D,
	camera = $Camera2D,
	interactUI = $InteractUI,
	interactUILabel = $InteractUI/ColorRect/Label,
	powerUI = $PowerUI
}

# Informations actuelles du joueur. Elles ne sont pas synchronisées entre les joueurs dans le MultiplayerSynchronizer
@export var INFO: Dictionary[StringName, Variant] = {
	# Statuts
	isMoving = false,
	
	# Statistiques
	currentSpeed = 100.00,
	maxSpiritRange = 150.00, # Rayon maximum auquel le Spirit peut se déplacer autour du Body
	power = 100.00,
	
	spawnCoordinates = Vector2(435.00, 170.00)
}

# Objets dont le joueur peut intéragir avec. Ils ne sont pas synchronisés entre les joueurs dans le MultiplayerSynchronizer
@export var INTERACTABLES: Dictionary[StringName, Node] = {
	frontDoor = null,
	backDoor = null,
	highVoltageStation = null
}

# Cout de chaque action utilisant INFO.power
@export var POWER_COST: Dictionary[StringName, float] = {
	interactWithDoor = 25.00,
	lockOrUnlockDoor = 10.00,
	interactWithHVS = 10.00,
	failedAction = 2.50
}

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(self.name)))

func _ready() -> void:
	self.global_position = INFO.spawnCoordinates
	add_to_group("spirits") # Ajout du noeud dans le groupe d'esprits
	
	if not is_multiplayer_authority(): return
	NODES.collisionShape.disabled = false
	NODES.powerUI.visible =  true
	
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

	# Le Spirit doit rester dans un rayon atour du Body
	velocity = Global.enforce_distance_from_host(inputVector, INFO.currentSpeed, self.global_position, INFO.maxSpiritRange, delta)
	velocity = Global.cartesian_to_isometric(velocity)
	set_velocity(velocity)
	move_and_slide()
	
func update_animated_sprite(anim: String) -> void:
	NODES.animatedSprite.animation = anim

# Deduit des points de INFO.power si au dessus de 0.00
func use_power(powerCost: float) -> bool:
	if (INFO.power - powerCost) > 0.00:
		INFO.power -= powerCost
		return true
	return false

@rpc("any_peer", "call_local")
func add_power(powerGrant: float) -> void:
	if not is_multiplayer_authority(): return
	
	if not (INFO.power > (100.00 - powerGrant)):
		INFO.power += powerGrant
		return
	INFO.power = 100.00
		
func set_interactable_front_door(door: Door) -> void:
	INTERACTABLES.frontDoor = door
	NODES.interactUI.visible = door != null
	if door != null:
		if door.INFO.opened:
			NODES.interactUILabel.text = "E - Fermer"
		else:
			NODES.interactUILabel.text = "E - Ouvrir"
	
func set_interactable_back_door(door: Door) -> void:
	INTERACTABLES.backDoor = door
	NODES.interactUI.visible = door != null
	if door != null:
		if door.INFO.locked:
			NODES.interactUILabel.text = "L - Dérouiller"
		else:
			if door.INFO.opened:
				NODES.interactUILabel.text = "E - Fermer"
			else:
				NODES.interactUILabel.text = "E - Ouvrir"
	
func set_interactable_HVS(highVoltageStation: HVS) -> void:
	INTERACTABLES.highVoltageStation = highVoltageStation
	NODES.interactUI.visible = highVoltageStation != null
	if highVoltageStation != null:
		if highVoltageStation._power:
			NODES.interactUILabel.text = "E - Eteindre"
		else:
			NODES.interactUILabel.text = "E - Allumer"
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("zoom out") and not NODES.camera.zoom <= Vector2(2.0, 2.0):
		NODES.camera.zoom -= Vector2(0.3, 0.3)
	elif event.is_action_pressed("zoom in") and not NODES.camera.zoom >= Vector2(10.0, 10.0):
		NODES.camera.zoom += Vector2(0.3, 0.3)
	
	if event.is_action_pressed("interact") and (INTERACTABLES.frontDoor or INTERACTABLES.backDoor):
		if INTERACTABLES.frontDoor and use_power(POWER_COST.interactWithDoor):
			INTERACTABLES.frontDoor.rpc("interact_with_front_door")
			set_interactable_front_door(INTERACTABLES.frontDoor)
		elif INTERACTABLES.backDoor and use_power(POWER_COST.interactWithDoor):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "interact")
			set_interactable_back_door(INTERACTABLES.backDoor)
	elif INTERACTABLES.backDoor and event.is_action_pressed("lock"):
		if use_power(POWER_COST.lockOrUnlockDoor):
			INTERACTABLES.backDoor.rpc("interact_with_back_door", "lock")
			set_interactable_back_door(INTERACTABLES.backDoor)
		
	elif INTERACTABLES.highVoltageStation and event.is_action_pressed("interact"):
		if use_power(POWER_COST.interactWithHVS):
			INTERACTABLES.highVoltageStation.rpc("switch_power_state")
			set_interactable_HVS(INTERACTABLES.highVoltageStation)
