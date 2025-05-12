extends CharacterBody2D

@onready var camera = $Camera2D

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

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready():
	if is_multiplayer_authority():
		camera.enabled = true
	else:
		camera.enabled = false
		

func _physics_process(delta):
	if !is_multiplayer_authority():
		return

		
	velocity = Vector2()

	if Input.is_action_just_pressed("ui_shift") and STAMINA > 0:
		SPEED = SPRINT_SPEED
		isSprinting = true
	if Input.is_action_just_released("ui_shift") or STAMINA <= 0:
		SPEED = WALK_SPEED
		isSprinting = false

	if Input.is_action_pressed("ui_w") or Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		isMoving = true
	elif Input.is_action_pressed("ui_s") or Input.is_action_pressed("ui_down"):
		velocity.y += 1
		isMoving = true
	elif Input.is_action_pressed("ui_d") or Input.is_action_pressed("ui_right"):
		velocity.x += 1
		isMoving = true
	elif Input.is_action_pressed("ui_a") or Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		isMoving = true
	else:
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

		
